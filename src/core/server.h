#pragma once

namespace strict {

class Server {
public:
    // Runs the event loop. Returns process exit code.
    int run(int argc, char** argv);
};

} // namespace strict
