cask "euclid" do
  version "0.2.11"
  sha256 :no_check  # Will be filled after first release

  url "https://github.com/botnetai/euclid/releases/download/v#{version}/Euclid-v#{version}.zip"
  name "Euclid"
  desc "On-device voice-to-text for macOS"
  homepage "https://github.com/botnetai/euclid"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :sequoia"
  depends_on arch: :arm64

  app "Euclid.app"

  zap trash: [
    "~/Library/Application Support/com.jjeremycai.Euclid",
    "~/Library/Caches/com.jjeremycai.Euclid",
    "~/Library/Containers/com.jjeremycai.Euclid",
    "~/Library/Preferences/com.jjeremycai.Euclid.plist",
  ]
end
