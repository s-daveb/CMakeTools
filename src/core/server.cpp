#include "core/server.h"
#include <libwebsockets.h>
#include <csignal>
#include <iostream>

namespace strict {

namespace {

// Signal handler for graceful shutdown
volatile sig_atomic_t stop_flag = 0;

void signal_handler(int) {
    stop_flag = 1;
}

// Minimal HTTP protocol handler
int http_callback(struct lws* wsi, enum lws_callback_reasons reason,
                  void* user, void* in, size_t len) {
    switch (reason) {
    case LWS_CALLBACK_HTTP:
        // Respond with simple text
        if (lws_return_http_status(wsi, HTTP_STATUS_OK, "text/plain") < 0)
            return -1;
        static const char body[] = "Strict backend\n";
        return lws_write(wsi, (unsigned char*)body, sizeof(body) - 1, LWS_WRITE_HTTP);
    default:
        break;
    }
    return 0;
}

// Protocol table
static struct lws_protocols protocols[] = {
    {"http", http_callback, 0, 0},
    {NULL, NULL, 0, 0} // terminator
};

} // namespace

int Server::run(int argc, char** argv) {
    // Install signal handlers
    std::signal(SIGINT, signal_handler);
    std::signal(SIGTERM, signal_handler);

    // libwebsockets context info
    struct lws_context_creation_info info{};
    info.port = 8080; // TODO: read from config; lighttpd reverse-proxies here
    info.protocols = protocols;
    info.gid = -1;
    info.uid = -1;

    struct lws_context* context = lws_create_context(&info);
    if (!context) {
        std::cerr << "Failed to create lws context\n";
        return EXIT_FAILURE;
    }

    std::cout << "Strict backend listening on :8080\n";

    // Event loop
    while (!stop_flag) {
        lws_service(context, 50);
    }

    lws_context_destroy(context);
    return EXIT_SUCCESS;
}

} // namespace strict
