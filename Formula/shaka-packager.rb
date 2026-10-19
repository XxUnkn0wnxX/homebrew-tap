require "language/python"

class ShakaPackager < Formula
  include Language::Python::Shebang

  desc "MPEG-DASH and HLS packaging tool"
  homepage "https://github.com/shaka-project/shaka-packager"
  license "BSD-3-Clause"

  # Always build from the latest commit on main of the stratumadev fork
  head "https://github.com/stratumadev/shaka-packager.git", branch: "main"

  depends_on "cmake" => :build
  depends_on "git" => :build
  depends_on "ninja" => :build
  depends_on "python@3.14"

  def install
    # Ensure all submodules are checked out for the current HEAD commit
    # (Homebrew usually does this, but this makes it explicit and ensures
    #  that all nested submodules are initialized as well.)
    system "git", "submodule", "update", "--init", "--recursive"

    # The shared-library link test runs a temporary install during the build.
    # Make that install wait for every installed CLI target, or parallel Ninja
    # can run it before shaka_decrypt exists.
    inreplace "link-test/CMakeLists.txt",
      "DEPENDS mpd_generator packager libpackager pssh_box_py",
      "DEPENDS mpd_generator packager shaka_decrypt libpackager pssh_box_py"

    # Keep older vendored CMake projects compatible with CMake 4.
    args = std_cmake_args + [
      "-GNinja",
      "-DBUILD_SHARED_LIBS=ON",
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
      "-DCMAKE_MAKE_PROGRAM=#{formula_opt_bin("ninja")}/ninja",
      "-DPython3_EXECUTABLE=#{formula_opt_bin("python@3.14")}/python3.14",
    ]
    # Avoid Homebrew's ambiguous bare-name lookup when both Shaka taps are present.
    args << "-DCMAKE_INSTALL_NAME_DIR=#{opt_lib}" if OS.mac?

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build", "--parallel"
    system "cmake", "--install", "build"

    rewrite_shebang detected_python_shebang, bin/"pssh-box.py"
  end

  test do
    system bin/"packager", "--version"
    system bin/"pssh-box.py", "--help"
  end
end
