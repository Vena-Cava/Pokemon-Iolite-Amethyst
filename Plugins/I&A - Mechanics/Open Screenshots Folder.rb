#===============================================================================
# Open Screenshots Folder with F7
#===============================================================================

module IAScreenshotFolder
  KEY = 118   # F7

  def self.folder_path
    save_dir = File.expand_path(System.data_directory)
    path = File.join(save_dir, "Screenshots")
    Dir.mkdir(path) if !Dir.safe?(path)
    return path
  end

  def self.open_folder
    path = folder_path.gsub("/", "\\")
    system("explorer.exe \"#{path}\"")
  end
end

module Graphics
  class << self
    alias ia_screenshot_folder_update update

    def update
      if Input.triggerex?(IAScreenshotFolder::KEY)
        IAScreenshotFolder.open_folder
      end

      ia_screenshot_folder_update
    end
  end
end