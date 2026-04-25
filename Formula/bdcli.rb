class Bdcli < Formula
  desc "BetterDiscord CLI fork for macOS 11 Big Sur on older Intel Macs"
  homepage "https://github.com/XxUnkn0wnxX/BDCLI"
  url "https://codeload.github.com/XxUnkn0wnxX/BDCLI/tar.gz/4b646b6002352bd10f00f63afc1157d2bd31b8f2"
  version "4b646b6"
  sha256 "312da2ad9dcb8a1cd5cbfae0978add41e2559a9355f960ddcccb86a0ea4c9d43"
  license "Apache-2.0"

  depends_on "xxunkn0wnxx/tap/go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    ENV["GOOS"] = "darwin"
    ENV["GOARCH"] = "amd64"
    ENV["GOAMD64"] = "v1"
    ENV["MACOSX_DEPLOYMENT_TARGET"] = "11.0"

    short_sha = version.to_s
    build_date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    ldflags = %W[
      -s -w
      -X main.version=#{short_sha}
      -X main.commit=#{short_sha}
      -X main.date=#{build_date}
    ]

    system "go", "build", *std_go_args(output: bin/"bdcli", ldflags: ldflags), "./main.go"
    generate_completions_from_executable(bin/"bdcli", "completion")

    pkgshare.install "README.md", "LICENSE"
  end

  test do
    assert_match "bdcli", shell_output("#{bin}/bdcli --help")
    assert_match "Print the version number", shell_output("#{bin}/bdcli help version")
  end
end
