#include "webview/webview.h"

#include <cstddef>
#include <cstring>
#include <string>
#include <windows.h>

namespace {
constexpr int kHotkeyIdToggleMiniBar = 1001;
constexpr int kBottomMarginPx = 16;
constexpr int kDefaultMiniBarWidth = 620;
constexpr int kDefaultMiniBarHeight = 104;
constexpr int kMiniBarCornerRadius = 28;

struct NativeState {
  webview_t minibar = nullptr;
  webview_t panel = nullptr;
  HWND minibar_hwnd = nullptr;
  HWND panel_hwnd = nullptr;
  WNDPROC minibar_prev_wndproc = nullptr;
  WNDPROC panel_prev_wndproc = nullptr;
  bool minibar_visible = true;
  int minibar_width = kDefaultMiniBarWidth;
  int minibar_height = kDefaultMiniBarHeight;
};

NativeState g_state;

using invoke_fn_t = int (*)(const char *req_json, char *out_json, size_t out_len);
invoke_fn_t g_invoke_handler = nullptr;

void position_minibar(HWND hwnd, int width, int height) {
  RECT work_area{};
  if (!SystemParametersInfoW(SPI_GETWORKAREA, 0, &work_area, 0)) {
    work_area.left = 0;
    work_area.top = 0;
    work_area.right = GetSystemMetrics(SM_CXSCREEN);
    work_area.bottom = GetSystemMetrics(SM_CYSCREEN);
  }

  const int x = work_area.left + ((work_area.right - work_area.left - width) / 2);
  const int y = work_area.bottom - height - kBottomMarginPx;
  SetWindowPos(hwnd, HWND_TOPMOST, x, y, width, height,
               SWP_NOACTIVATE | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
}

int env_int_or_default(const char *name, int fallback) {
  char buf[32]{};
  DWORD len = GetEnvironmentVariableA(name, buf, sizeof(buf));
  if (len == 0 || len >= sizeof(buf)) {
    return fallback;
  }
  int value = atoi(buf);
  return value > 0 ? value : fallback;
}

void apply_round_region(HWND hwnd, int width, int height) {
  HRGN region = CreateRoundRectRgn(0, 0, width, height, kMiniBarCornerRadius,
                                   kMiniBarCornerRadius);
  if (region) {
    SetWindowRgn(hwnd, region, TRUE);
  }
}

void style_minibar(HWND hwnd, int width, int height) {
  LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX |
             WS_SYSMENU);
  style |= WS_POPUP;
  SetWindowLongPtrW(hwnd, GWL_STYLE, style);

  LONG_PTR exstyle = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
  exstyle |= WS_EX_TOPMOST | WS_EX_TOOLWINDOW;
  SetWindowLongPtrW(hwnd, GWL_EXSTYLE, exstyle);

  apply_round_region(hwnd, width, height);
  position_minibar(hwnd, width, height);
}

LRESULT CALLBACK panel_wndproc(HWND hwnd, UINT msg, WPARAM wparam,
                               LPARAM lparam) {
  if (msg == WM_CLOSE) {
    ShowWindow(hwnd, SW_HIDE);
    return 0;
  }

  if (msg == WM_DESTROY) {
    g_state.panel_hwnd = nullptr;
  }

  if (g_state.panel_prev_wndproc) {
    return CallWindowProcW(g_state.panel_prev_wndproc, hwnd, msg, wparam, lparam);
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

LRESULT CALLBACK minibar_wndproc(HWND hwnd, UINT msg, WPARAM wparam,
                                 LPARAM lparam) {
  if (msg == WM_HOTKEY && static_cast<int>(wparam) == kHotkeyIdToggleMiniBar) {
    g_state.minibar_visible = !g_state.minibar_visible;
    if (g_state.minibar_visible) {
      ShowWindow(hwnd, SW_SHOWNOACTIVATE);
      position_minibar(hwnd, g_state.minibar_width, g_state.minibar_height);
    } else {
      ShowWindow(hwnd, SW_HIDE);
    }
    return 0;
  }

  if (msg == WM_DESTROY) {
    UnregisterHotKey(hwnd, kHotkeyIdToggleMiniBar);
  }

  if (g_state.minibar_prev_wndproc) {
    return CallWindowProcW(g_state.minibar_prev_wndproc, hwnd, msg, wparam,
                           lparam);
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

bool install_hotkey(HWND hwnd) {
  return RegisterHotKey(hwnd, kHotkeyIdToggleMiniBar, MOD_ALT, 'R') != 0;
}
}  // namespace

static void invoke_handler(const char *seq, const char *req, void *arg) {
  (void)arg;
  std::string out(8192, '\0');
  auto fn = g_invoke_handler;
  int status = 1;
  if (fn) {
    status = fn(req, &out[0], out.size());
  }
  if (status != 0) {
    const char *fallback = "{\"code\":\"native_failure\",\"message\":\"Native invoke bridge failed or unresolved\"}";
    const char *payload = out[0] != '\0' ? out.c_str() : fallback;
    webview_return((webview_t)arg, seq, 1, payload);
    return;
  }
  webview_return((webview_t)arg, seq, 0, out.c_str());
}

extern "C" void mini_webview_set_invoke_handler(invoke_fn_t fn) {
  g_invoke_handler = fn;
}

extern "C" int mini_webview_open_control_panel() {
  if (!g_state.panel_hwnd || !IsWindow(g_state.panel_hwnd)) {
    return 1;
  }
  ShowWindow(g_state.panel_hwnd, SW_SHOW);
  ShowWindow(g_state.panel_hwnd, SW_RESTORE);
  SetForegroundWindow(g_state.panel_hwnd);
  SetWindowPos(g_state.panel_hwnd, HWND_TOP, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE);
  return 0;
}

extern "C" int mini_webview_run_shell(int debug, const char *minibar_url,
                                      const char *control_panel_url) {
  g_state = NativeState{};
  SetEnvironmentVariableA("WEBVIEW2_DEFAULT_BACKGROUND_COLOR", "00FFFFFF");
  g_state.minibar_width =
      env_int_or_default("MINIBAR_WIDTH", kDefaultMiniBarWidth);
  g_state.minibar_height =
      env_int_or_default("MINIBAR_HEIGHT", kDefaultMiniBarHeight);

  g_state.minibar = webview_create(debug, NULL);
  g_state.panel = webview_create(debug, NULL);
  if (!g_state.minibar || !g_state.panel) {
    if (g_state.minibar) {
      webview_destroy(g_state.minibar);
    }
    if (g_state.panel) {
      webview_destroy(g_state.panel);
    }
    g_state = NativeState{};
    return 1;
  }

  webview_set_title(g_state.minibar, "MiniBar");
  webview_set_size(g_state.minibar, g_state.minibar_width, g_state.minibar_height,
                   WEBVIEW_HINT_FIXED);
  webview_bind(g_state.minibar, "__invoke__", invoke_handler, g_state.minibar);
  webview_navigate(g_state.minibar, minibar_url);

  webview_set_title(g_state.panel, "Control Panel");
  webview_set_size(g_state.panel, 980, 680, WEBVIEW_HINT_NONE);
  webview_bind(g_state.panel, "__invoke__", invoke_handler, g_state.panel);
  webview_navigate(g_state.panel, control_panel_url);

  g_state.minibar_hwnd = static_cast<HWND>(
      webview_get_native_handle(g_state.minibar, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW));
  g_state.panel_hwnd = static_cast<HWND>(
      webview_get_native_handle(g_state.panel, WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW));

  if (!g_state.minibar_hwnd || !g_state.panel_hwnd) {
    webview_destroy(g_state.panel);
    webview_destroy(g_state.minibar);
    g_state = NativeState{};
    return 1;
  }

  style_minibar(g_state.minibar_hwnd, g_state.minibar_width,
                g_state.minibar_height);
  g_state.minibar_prev_wndproc = reinterpret_cast<WNDPROC>(
      SetWindowLongPtrW(g_state.minibar_hwnd, GWLP_WNDPROC,
                        reinterpret_cast<LONG_PTR>(minibar_wndproc)));
  g_state.panel_prev_wndproc = reinterpret_cast<WNDPROC>(
      SetWindowLongPtrW(g_state.panel_hwnd, GWLP_WNDPROC,
                        reinterpret_cast<LONG_PTR>(panel_wndproc)));
  install_hotkey(g_state.minibar_hwnd);

  ShowWindow(g_state.panel_hwnd, SW_HIDE);

  webview_run(g_state.minibar);

  if (g_state.panel) {
    webview_destroy(g_state.panel);
  }
  if (g_state.minibar) {
    webview_destroy(g_state.minibar);
  }
  g_state = NativeState{};
  return 0;
}

extern "C" int mini_webview_run_app(int debug, const char *title, int width,
                                    int height, int hint,
                                    const char *start_url) {
  webview_t w = webview_create(debug, NULL);
  if (!w) {
    return 1;
  }

  webview_set_title(w, title);
  webview_set_size(w, width, height, static_cast<webview_hint_t>(hint));
  webview_bind(w, "__invoke__", invoke_handler, w);
  webview_navigate(w, start_url);
  webview_run(w);
  webview_destroy(w);
  return 0;
}
