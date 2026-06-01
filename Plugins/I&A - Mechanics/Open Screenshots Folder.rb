#===============================================================================
# Open Screenshots Folder with F9
#===============================================================================

module IAScreenshotFolder
  KEY = Input::F9

  def self.folder_path
    save_dir = File.directory?(System.data_directory) ? System.data_directory : "."
    path = sprintf("%s/Screenshots", save_dir)
    Dir.mkdir(path) if !Dir.safe?(path)
    return path
  end

  def self.open_folder
    path = folder_path.gsub("/", "\\")

    if System.platform[/Windows/i]
      system("explorer \"#{path}\"")
    else
      system("open \"#{folder_path}\"")
    end
  end
end

class Scene_Map
  alias ia_screenshot_folder_update update

  def update
    ia_screenshot_folder_update

    echoln "F9 pressed" if Input.triggerex?(VK_F9)

    if Input.triggerex?(VK_F9)
      IAScreenshotFolder.open_folder
    end
  end
end