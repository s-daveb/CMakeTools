#include <cstdlib>
#include "core/server.h"

int main(int argc, char** argv) {
    // TODO: parse config, set up signal handlers, drop privileges.
    strict::Server server;
    return server.run(argc, argv);
}
