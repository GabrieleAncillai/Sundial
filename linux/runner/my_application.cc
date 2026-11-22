#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <gio/gio.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* window_channel;
  GtkCssProvider* window_css;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static const char kWindowTitle[] = "Sundial";
static const char kWindowChannel[] = "io.github.sundial/window";

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// GNOME-family desktops expect a header bar and, on Wayland, cannot ask the
// compositor for server-side decorations. Other desktops keep their own frame.
static gboolean desktop_is_gnome_family(void) {
  const gchar* desktop = g_getenv("XDG_CURRENT_DESKTOP");
  if (desktop != nullptr && *desktop != '\0') {
    gboolean gnome = FALSE;
    gchar** names = g_strsplit(desktop, ":", -1);
    for (gint i = 0; names[i] != nullptr; i++) {
      if (g_ascii_strcasecmp(names[i], "GNOME") == 0 ||
          g_ascii_strcasecmp(names[i], "Unity") == 0 ||
          g_ascii_strcasecmp(names[i], "Pantheon") == 0 ||
          g_ascii_strcasecmp(names[i], "Budgie") == 0) {
        gnome = TRUE;
        break;
      }
    }
    g_strfreev(names);
    return gnome;
  }

#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gdk_screen_get_default();
  if (screen != nullptr && GDK_IS_X11_SCREEN(screen)) {
    return g_strcmp0(gdk_x11_screen_get_window_manager_name(screen), "GNOME Shell") == 0;
  }
#endif

  // Wayland with no desktop hint: draw our own themed bar rather than leaving
  // the window without a frame.
  return TRUE;
}

// GTK3 does not follow the freedesktop color-scheme preference by itself, so
// read the portal and use it for the initial frame and GTK-native dialogs.
static gboolean system_prefers_dark(void) {
  gboolean gtk_dark = FALSE;
  g_object_get(gtk_settings_get_default(), "gtk-application-prefer-dark-theme", &gtk_dark, NULL);

  g_autoptr(GDBusConnection) bus = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (bus == nullptr) {
    return gtk_dark;
  }

  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      bus,
      "org.freedesktop.portal.Desktop",
      "/org/freedesktop/portal/desktop",
      "org.freedesktop.portal.Settings",
      "Read",
      g_variant_new("(ss)", "org.freedesktop.appearance", "color-scheme"),
      G_VARIANT_TYPE("(v)"),
      G_DBUS_CALL_FLAGS_NONE,
      1000,
      nullptr,
      nullptr);
  if (reply == nullptr) {
    return gtk_dark;
  }

  g_autoptr(GVariant) child = g_variant_get_child_value(reply, 0);
  if (!g_variant_is_of_type(child, G_VARIANT_TYPE_VARIANT)) {
    return gtk_dark;
  }
  g_autoptr(GVariant) value = g_variant_get_variant(child);
  if (value == nullptr || !g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
    return gtk_dark;
  }

  const guint32 scheme = g_variant_get_uint32(value);
  if (scheme == 1) return TRUE;   // prefer-dark
  if (scheme == 2) return FALSE;  // prefer-light
  return gtk_dark;
}

static gboolean high_contrast_enabled(void) {
  gchar* theme_name = nullptr;
  g_object_get(gtk_settings_get_default(), "gtk-theme-name", &theme_name, NULL);
  const gboolean high_contrast =
      theme_name != nullptr && g_strstr_len(theme_name, -1, "HighContrast") != nullptr;
  g_free(theme_name);
  return high_contrast;
}

static guint32 color_from_args(FlValue* args, const gchar* key, guint32 fallback) {
  FlValue* value = fl_value_lookup_string(args, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_INT) {
    return fallback;
  }
  const gint64 raw = fl_value_get_int(value);
  if (raw < 0 || raw > 0xFFFFFFFFLL) {
    return fallback;
  }
  return static_cast<guint32>(raw);
}

static gchar* css_rgba(guint32 argb) {
  return g_strdup_printf("rgba(%u, %u, %u, %.3f)",
                         static_cast<guint>((argb >> 16) & 0xff),
                         static_cast<guint>((argb >> 8) & 0xff),
                         static_cast<guint>(argb & 0xff),
                         ((argb >> 24) & 0xff) / 255.0);
}

// The header bar is drawn by GTK, not Flutter. Painting it with the app palette
// keeps a dark app from sitting under a light system title bar.
static void apply_window_palette(MyApplication* self, FlValue* args) {
  FlValue* dark_value = fl_value_lookup_string(args, "dark");
  const gboolean dark = dark_value != nullptr &&
                        fl_value_get_type(dark_value) == FL_VALUE_TYPE_BOOL &&
                        fl_value_get_bool(dark_value);

  if (high_contrast_enabled()) {
    if (self->window_css != nullptr) {
      gtk_css_provider_load_from_data(self->window_css, "", -1, nullptr);
    }
    return;
  }

  g_object_set(gtk_settings_get_default(), "gtk-application-prefer-dark-theme", dark, NULL);
  if (self->window_css == nullptr) {
    return;
  }

  const guint32 page_bg = color_from_args(args, "pageBg", dark ? 0xFF0F1210 : 0xFFF6F4EF);
  const guint32 surface_high = color_from_args(args, "surfaceHigh", dark ? 0xFF2B322C : 0xFFE7E3DA);
  const guint32 border = color_from_args(args, "border", dark ? 0xFF313832 : 0xFFDED9CF);
  const guint32 text = color_from_args(args, "text", dark ? 0xFFF2F0EB : 0xFF1D1B17);
  const guint32 text_secondary = color_from_args(args, "textSecondary", dark ? 0xFFA7ADA5 : 0xFF5C574F);
  const guint32 danger = color_from_args(args, "danger", dark ? 0xFFE5674C : 0xFFB3402F);
  const guint32 danger_soft = color_from_args(args, "dangerSoft", dark ? 0x29E5674C : 0x1FB3402F);

  g_autofree gchar* page_bg_css = css_rgba(page_bg);
  g_autofree gchar* surface_high_css = css_rgba(surface_high);
  g_autofree gchar* border_css = css_rgba(border);
  g_autofree gchar* text_css = css_rgba(text);
  g_autofree gchar* text_secondary_css = css_rgba(text_secondary);
  g_autofree gchar* danger_css = css_rgba(danger);
  g_autofree gchar* danger_soft_css = css_rgba(danger_soft);

  g_autoptr(GString) css = g_string_new(nullptr);
  g_string_append_printf(
      css,
      "headerbar {"
      "  min-height: 40px;"
      "  padding: 0 6px;"
      "  background-color: %s;"
      "  background-image: none;"
      "  border-bottom: 1px solid %s;"
      "  box-shadow: none;"
      "  color: %s;"
      "}\n"
      "headerbar:backdrop {"
      "  background-color: %s;"
      "  color: %s;"
      "}\n"
      "headerbar .title {"
      "  font-size: 13px;"
      "  font-weight: 600;"
      "  color: %s;"
      "}\n"
      "headerbar button.titlebutton {"
      "  background: transparent;"
      "  background-image: none;"
      "  border: none;"
      "  box-shadow: none;"
      "  color: %s;"
      "}\n"
      "headerbar button.titlebutton:hover {"
      "  background-color: %s;"
      "  border-radius: 6px;"
      "}\n"
      "headerbar button.titlebutton:active {"
      "  background-color: %s;"
      "}\n"
      "headerbar button.titlebutton.close:hover,"
      "headerbar button.titlebutton.close:active {"
      "  background-color: %s;"
      "  color: %s;"
      "}\n",
      page_bg_css,
      border_css,
      text_css,
      page_bg_css,
      text_secondary_css,
      text_css,
      text_css,
      surface_high_css,
      surface_high_css,
      danger_soft_css,
      danger_css);
  gtk_css_provider_load_from_data(self->window_css, css->str, -1, nullptr);
}

static void window_method_call(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  (void)channel;
  MyApplication* self = MY_APPLICATION(user_data);
  FlValue* args = fl_method_call_get_args(call);
  if (g_strcmp0(fl_method_call_get_name(call), "apply") == 0 && args != nullptr &&
      fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    apply_window_palette(self, args);
    fl_method_call_respond_success(call, nullptr, nullptr);
    return;
  }
  fl_method_call_respond_not_implemented(call, nullptr);
}

static void configure_window_chrome(MyApplication* self, GtkWindow* window) {
  gtk_window_set_title(window, kWindowTitle);

  if (desktop_is_gnome_family()) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, kWindowTitle);
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  }

  self->window_css = gtk_css_provider_new();
  gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),
                                            GTK_STYLE_PROVIDER(self->window_css),
                                            GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

  if (!high_contrast_enabled()) {
    g_object_set(gtk_settings_get_default(),
                 "gtk-application-prefer-dark-theme",
                 system_prefers_dark(),
                 NULL);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  configure_window_chrome(self, window);
  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);

  // Register before the engine starts at realize so the first palette call
  // cannot race the handler.
  g_clear_object(&self->window_channel);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->window_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kWindowChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->window_channel, window_method_call, self, nullptr);

  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_object(&self->window_channel);
  g_clear_object(&self->window_css);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
