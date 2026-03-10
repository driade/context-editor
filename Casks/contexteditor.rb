cask "contexteditor" do
  version "0.1.2"
  sha256 "14a4d0c605b7e73ddb2737ea7f29c19e24efb452cdb027c6414397230cc6ff75"

  url "https://github.com/driade/context-editor/releases/download/v#{version}/ContextEditor-macOS.zip"
  name "ContextEditor"
  desc "Route text files to different editors depending on the current project"
  homepage "https://github.com/driade/context-editor"

  depends_on macos: ">= :ventura"

  app "ContextEditor.app"
end
