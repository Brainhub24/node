#ifndef SRC_NODE_SEA_H_
#define SRC_NODE_SEA_H_

#if defined(NODE_WANT_INTERNALS) && NODE_WANT_INTERNALS

#if !defined(DISABLE_SINGLE_EXECUTABLE_APPLICATION)

#include <string_view>
#include <tuple>
#include "node_exit_code.h"

namespace node {
namespace sea {
// A special number that will appear at the beginning of the single executable
// preparation blobs ready to be injected into the binary. We use this to check
// that the data given to us are intended for building single executable
// applications.
const uint32_t kMagic = 0x143da20;

enum class SeaFlags : uint32_t {
  kDefault = 0,
  kDisableExperimentalSeaWarning = 1 << 0,
};

struct SeaResource {
  SeaFlags flags = SeaFlags::kDefault;
  std::string_view code;

  static constexpr size_t kHeaderSize = sizeof(kMagic) + sizeof(SeaFlags);
};

bool IsSingleExecutable();
SeaResource FindSingleExecutableResource();
std::tuple<int, char**> FixupArgsForSEA(int argc, char** argv);
node::ExitCode BuildSingleExecutableBlob(const std::string& config_path);
}  // namespace sea
}  // namespace node

#endif  // !defined(DISABLE_SINGLE_EXECUTABLE_APPLICATION)

#endif  // defined(NODE_WANT_INTERNALS) && NODE_WANT_INTERNALS

#endif  // SRC_NODE_SEA_H_
