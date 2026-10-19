class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  url "https://go.dev/dl/go1.27.2.src.tar.gz"
  mirror "https://fossies.org/linux/misc/go1.27.2.src.tar.gz"
  sha256 "03495da2ba64894d40f5c4992e49454fa78b50690604ff92b6afff5081b76e62"
  license "BSD-3-Clause"
  head "https://go.googlesource.com/go.git", branch: "master"

  livecheck do
    url "https://go.dev/dl/?mode=json"
    regex(/^go[._-]?v?(\d+(?:\.\d+)+)[._-]src\.t.+$/i)
    strategy :json do |json, regex|
      json.map do |release|
        next if release["stable"] != true
        next if release["files"].none? { |file| file["filename"].match?(regex) }

        release["version"][/(\d+(?:\.\d+)+)/, 1]
      end
    end
  end

  keg_only :versioned_formula

  on_macos do
    depends_on macos: :big_sur
  end

  # Don't update this unless this version cannot bootstrap the new version.
  resource "gobootstrap" do
    checksums = {
      "darwin-arm64" => "f282d882c3353485e2fc6c634606d85caf36e855167d59b996dbeae19fa7629a",
      "darwin-amd64" => "6cc6549b06725220b342b740497ffd24e0ebdcef75781a77931ca199f46ad781",
      "linux-arm64"  => "74d97be1cc3a474129590c67ebf748a96e72d9f3a2b6fef3ed3275de591d49b3",
      "linux-amd64"  => "1fc94b57134d51669c72173ad5d49fd62afb0f1db9bf3f798fd98ee423f8d730",
    }

    version "1.24.13"

    on_arm do
      on_macos do
        url "https://go.dev/dl/go#{version}.darwin-arm64.tar.gz"
        sha256 checksums["darwin-arm64"]
      end
      on_linux do
        url "https://go.dev/dl/go#{version}.linux-arm64.tar.gz"
        sha256 checksums["linux-arm64"]
      end
    end
    on_intel do
      on_macos do
        url "https://go.dev/dl/go#{version}.darwin-amd64.tar.gz"
        sha256 checksums["darwin-amd64"]
      end
      on_linux do
        url "https://go.dev/dl/go#{version}.linux-amd64.tar.gz"
        sha256 checksums["linux-amd64"]
      end
    end
  end

  env :std
  deny_network_access!

  def replace_source_once(path, before, after)
    source = Pathname(path)
    # Homebrew inreplace reads bytes; assembly identifiers contain UTF-8 middle dots.
    count = source.binread.scan(Regexp.new(Regexp.escape(before.b))).length
    raise "Go Big Sur backport: expected one source anchor in #{path}, found #{count}" unless count == 1

    inreplace source, before.b, after.b
  end

  def backport_big_sur
    # Go >=1.25 imports a macOS 12-only symbol even without cgo, aborting on Big Sur.
    # Restore only Go 1.24's certificate enumeration; keep current trust verification.
    # MacPorts documents the same cliff in its go_toolchain-1.0 PortGroup.
    replace_source_once "src/crypto/x509/internal/macos/security.go", <<~OLD, <<~NEW
      //go:cgo_import_dynamic x509_SecTrustCopyCertificateChain SecTrustCopyCertificateChain "/System/Library/Frameworks/Security.framework/Versions/A/Security"

      func SecTrustCopyCertificateChain(trustObj CFRef) (CFRef, error) {
      \tret := syscall(abi.FuncPCABI0(x509_SecTrustCopyCertificateChain_trampoline), uintptr(trustObj), 0, 0, 0, 0, 0)
      \tif ret == 0 {
      \t\treturn 0, OSStatus{"SecTrustCopyCertificateChain", int32(ret)}
      \t}
      \treturn CFRef(ret), nil
      }
      func x509_SecTrustCopyCertificateChain_trampoline()
    OLD
      //go:cgo_import_dynamic x509_SecTrustGetCertificateCount SecTrustGetCertificateCount "/System/Library/Frameworks/Security.framework/Versions/A/Security"

      func SecTrustGetCertificateCount(trustObj CFRef) int {
      \tret := syscall(abi.FuncPCABI0(x509_SecTrustGetCertificateCount_trampoline), uintptr(trustObj), 0, 0, 0, 0, 0)
      \treturn int(ret)
      }
      func x509_SecTrustGetCertificateCount_trampoline()

      //go:cgo_import_dynamic x509_SecTrustGetCertificateAtIndex SecTrustGetCertificateAtIndex "/System/Library/Frameworks/Security.framework/Versions/A/Security"

      func SecTrustGetCertificateAtIndex(trustObj CFRef, i int) (CFRef, error) {
      \tret := syscall(abi.FuncPCABI0(x509_SecTrustGetCertificateAtIndex_trampoline), uintptr(trustObj), uintptr(i), 0, 0, 0, 0)
      \tif ret == 0 {
      \t\treturn 0, OSStatus{"SecTrustGetCertificateAtIndex", int32(ret)}
      \t}
      \treturn CFRef(ret), nil
      }
      func x509_SecTrustGetCertificateAtIndex_trampoline()
    NEW

    replace_source_once "src/crypto/x509/internal/macos/security.s", <<~OLD, <<~NEW
      TEXT ·x509_SecTrustCopyCertificateChain_trampoline(SB),NOSPLIT,$0-0
      \tJMP x509_SecTrustCopyCertificateChain(SB)
    OLD
      TEXT ·x509_SecTrustGetCertificateCount_trampoline(SB),NOSPLIT,$0-0
      \tJMP x509_SecTrustGetCertificateCount(SB)
      TEXT ·x509_SecTrustGetCertificateAtIndex_trampoline(SB),NOSPLIT,$0-0
      \tJMP x509_SecTrustGetCertificateAtIndex(SB)
    NEW

    # The evaluated trustObj stays alive until after these borrowed refs are exported.
    # Do not release the refs or share/mutate that trust object concurrently.
    replace_source_once "src/crypto/x509/root_darwin.go", <<~OLD.gsub(/^/, "\t"), <<~NEW.gsub(/^/, "\t")
        chain := [][]*Certificate{{}}
        chainRef, err := macos.SecTrustCopyCertificateChain(trustObj)
        if err != nil {
        \treturn nil, err
        }
        defer macos.CFRelease(chainRef)
        for i := 0; i < macos.CFArrayGetCount(chainRef); i++ {
        \tcertRef := macos.CFArrayGetValueAtIndex(chainRef, i)
    OLD
        chain := [][]*Certificate{{}}
        numCerts := macos.SecTrustGetCertificateCount(trustObj)
        for i := 0; i < numCerts; i++ {
        \tcertRef, err := macos.SecTrustGetCertificateAtIndex(trustObj, i)
        \tif err != nil {
        \t\treturn nil, err
        \t}
    NEW

    # Apply before toolchain1 so every bootstrap linker and later Go binary inherits it.
    replace_source_once "src/cmd/link/internal/ld/macho.go",
                        "\tmacOS  = macVersionFlag{13, 0, 0}\n", "\tmacOS  = macVersionFlag{11, 0, 0}\n"
    # Official auto-downloaded toolchains lack this backport and cannot run on Big Sur.
    # Keep normal module proxy/checksum defaults and user configuration untouched.
    replace_source_once "go.env", "GOTOOLCHAIN=auto\n", "GOTOOLCHAIN=local\n"
  end

  def install
    if OS.mac? && MacOS.version <= :big_sur
      backport_big_sur
      ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"
    end

    libexec.install Dir["*"]
    (buildpath/"gobootstrap").install resource("gobootstrap")
    ENV["GOROOT_BOOTSTRAP"] = buildpath/"gobootstrap"
    ENV["GOTOOLCHAIN"] = "local"
    ENV["GOENV"] = "off"
    ENV["GOWORK"] = "off"
    ENV["GOPROXY"] = "off"
    ENV["GOSUMDB"] = "off"
    # cmd/dist also has its own four-job scheduler; keep every bootstrap stage.
    ENV["GOMAXPROCS"] = [[ENV.make_jobs.to_i, 1].max, 4].min.to_s

    cd libexec/"src" do
      # Set portable defaults for CC/CXX to be used by cgo
      with_env(CC: "cc", CXX: "c++") { system "./make.bash" }
    end

    bin.install_symlink Dir[libexec/"bin/go*"]

    # Remove useless files.
    # Breaks patchelf because folder contains weird debug/test files
    rm_r(libexec/"src/debug/elf/testdata")
    # Binaries built for an incompatible architecture
    rm_r(libexec/"src/runtime/pprof/testdata")
    # Remove testdata with binaries for non-native architectures.
    rm_r(libexec/"src/debug/dwarf/testdata")
  end

  def caveats
    <<~EOS
      This formula carries a best-effort Big Sur x509 and linker backport.
      Go 1.24.13 is downloaded as an isolated bootstrap build resource;
      an existing Go installation is not required or replaced by the bootstrap.
      The previous Go 1.24.8 formula is saved at backups/go-1.24.8.rb in this tap.
      On Big Sur, toolchain selection defaults to local because official newer
      toolchains do not include this backport; explicit Go configuration can override it.
      The source build has been reported working on Intel Big Sur.
      Native certificate verification, cgo and other platforms need runtime qualification.
    EOS
  end

  test do
    (testpath/"hello.go").write <<~GO
      package main

      import "fmt"

      func main() {
          fmt.Println("Hello World")
      }
    GO

    # Run go fmt check for no errors then run the program.
    # This is a a bare minimum of go working as it uses fmt, build, and run.
    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

    with_env(GOOS: "freebsd", GOARCH: "amd64") do
      system bin/"go", "build", "hello.go"
    end

    (testpath/"hello_cgo.go").write <<~GO
      package main

      /*
      #include <stdlib.h>
      #include <stdio.h>
      void hello() { printf("%s\\n", "Hello from cgo!"); fflush(stdout); }
      */
      import "C"

      func main() {
          C.hello()
      }
    GO

    # Try running a sample using cgo without CC or CXX set to ensure that the
    # toolchain's default choice of compilers work
    with_env(CC: nil, CXX: nil, CGO_ENABLED: "1") do
      assert_equal "Hello from cgo!\n", shell_output("#{bin}/go run hello_cgo.go")
    end
  end
end
