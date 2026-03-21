#include "webview/webview.h"

#include <cstddef>
#include <cstring>
#include <string>

extern "C" int mini_webview_handle_invoke(const char *req_json, char *out_json,
                                          size_t out_len);

static void invoke_handler(const char *seq, const char *req, void *arg) {
  (void)arg;
  std::string out(8192, '\0');
  int status = mini_webview_handle_invoke(req, &out[0], out.size());
  if (status != 0) {
    const char *fallback = "{\"code\":\"native_failure\",\"message\":\"Native invoke bridge failed\"}";
    const char *payload = out[0] != '\0' ? out.c_str() : fallback;
    webview_return((webview_t)arg, seq, 1, payload);
    return;
  }
  webview_return((webview_t)arg, seq, 0, out.c_str());
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
