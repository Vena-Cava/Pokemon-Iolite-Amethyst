#=============================================================================
# Swdfm Utilites - Bitmaps
# Last Updated: 2023-12-04
#=============================================================================
module Swd_Bitmap
  # Usually used for animated sprites with no foreground!
  def self.empty(w, h)
    ret = Bitmap.new(w, h)
    return ret
  end
  
  # Gets the straight up bitmap from file
  def self.direct(file)
    p, f = Swd.split_file(file)
    return RPG::Cache.load_bitmap(p, f, 0)
  end
  
  # Returns a bitmap
  # w, h is width, height of returned bitmap
  # bmp is placed on returned empty bitmap
  # For when a bitmap is smaller than other layered bitmaps
  def self.place_on_canvas(bmp, w, h = nil, anchor = :C, y = nil)
    h = w unless h
    o_w = bmp.width
    o_h = bmp.height
    g_w = w - o_w # gap width
    g_h = h - o_h # gap height
    if anchor.is_a?(Integer)
      x = anchor
    else
      # Let's do Xs first!
      x = g_w # :NE, :E, :SE
      case anchor
      when :NW, :W, :SW
        x = 0
      when :N,  :C, :S
        x = g_w / 2
      end
    end
    # Now we'll do Ys!
    if anchor.is_a?(Integer)
      y = 0 unless y
    else
      y = g_h # :SW, :S, :SE
      case anchor
      when :NW, :N, :NE
        y = 0
      when :W,  :C, :E
        y = g_h / 2
      end
    end
    ret = self.empty(w, h)
    ret.blt(x, y, bmp, Rect.new(0, 0, o_w, o_h))
    return ret
  end
  
  # Inserts a bitmap, then a  rect of x, y, w, height
  # x_1 and y_1 determine a gap in final image if you want one
  def self.src_rect_set(bmp, x, y, w, h = nil)
    h = w unless h
    ret = self.empty(w, h)
    ret.blt(0, 0, bmp, Rect.new(x, y, w, h))
    return ret
  end
  
  # Src_Rect_Set, but Inputs a file instead of another Bitmap
  def self.src_rect_set_file(file, x, y, w, h = nil)
    bmp  = self.direct(file)
    return self.src_rect_set(bmp, x, y, w, h)
  end
  
  # Colours a bitmap with a defined colour in a defined space
  def self.colour(bmp, col, x, y, w, h)
    if !bmp
      bmp = self.empty(w, h)
    elsif bmp.is_a?(Array)
      bmp = self.empty(*bmp)
    end
    bmp.fill_rect(x, y, w, h, col)
    return bmp
  end
  
  # Basically two lots of self.colour
  def self.box(bmp, e_col, f_col, e)
    bmp = self.empty(*bmp) if bmp.is_a?(Array)
    w   = bmp.width
    h   = bmp.height
    bmp.fill_rect(0, 0, w, h, e_col)
    bmp.fill_rect(e, e, w - 2 * e, h - 2 * e, f_col)
    return bmp
  end
  
  # Basically a box but hollowed out
  def self.cursor(bmp, e_col, e)
    bmp = self.empty(*bmp) if bmp.is_a?(Array)
    w   = bmp.width
    h   = bmp.height
    bmp.fill_rect(0, 0, w, e, e_col)
    bmp.fill_rect(0, 0, e, h, e_col)
    bmp.fill_rect(0, h - e, w, e, e_col)
    bmp.fill_rect(w - e, 0, e, h, e_col)
    return bmp
  end
  
  # first and second are an array of 3 [r, g, b] or Color object
  # s_w and s_h stand for segment width/height
  def self.gradient(first, second, w, h, s_w = nil, s_h = nil, dir = :VERTICAL, bmp = nil)
    if first.is_a?(Color)
      first = [first.red, first.green, first.blue, first.alpha]
    end
    if second.is_a?(Color)
      second = [second.red, second.green, second.blue, second.alpha]
    end
    first.push(255)  if first.length == 3
    second.push(255) if second.length == 3
    s_w = 1 unless s_w
    s_h = 1 unless s_h
    # Added For Superimposition
    ret = bmp || self.empty(w, h)
    x = bmp ? (bmp.width - w) / 2 : 0
    y = bmp ? (bmp.height - h) / 2 : 0
    segments = dir == :VERTICAL ? h / s_h : w / s_w
    for i in 0...segments
      col = []
      for j in 0...4
        col.push([first[j] + (i * (second[j] - first[j]) /   segments).floor, 255].min)
      end
      r, g, b, a = col
      col        = Color.new(r, g, b, a)
      case dir
      when :VERTICAL
        ret.fill_rect(x, y + s_h * i, w, s_h, col)
      else
        ret.fill_rect(x + s_w * i, y, s_w, h, col)
      end
    end
    return ret
  end
  
  # Saves a lot of drama with zoom_x and zoom_y!
  # Inputs a file, and enlarges it by a scale of zoom
  # May be expensive, so try not to use with large sprites!
  def self.enlarge(bmp, zoom_x = 1, zoom_y = nil)
    return self.enlarge_smaller(bmp, zoom_x = 1) if zoom_x.is_a?(Symbol)
    return bmp if zoom_x == 1
    zoom_y = zoom_x if !zoom_y
    w   = bmp.width
    h   = bmp.height
    ret = self.empty(w * zoom_x, h * zoom_y)
    for x in 0...w
      for y in 0...h
        col = bmp.get_pixel(x, y)
        ret.fill_rect(x * zoom_x, y * zoom_y, zoom_x, zoom_y, col)
      end
    end
    return ret
  end
  
  def self.enlarge_smaller(bmp, zoom_x = :A_Half, zoom_y = nil)
    w = bmp.width
    h = bmp.height
    n = 1
    d = 1
    if zoom_x.is_a?(Integer)
      n = zoom_x
    else
      case zoom_x
      when :A_Half
        d = 2
      when :Two_Thirds
        n = 2
        d = 3
      end
    end
    ret = self.empty(w * n / d, h * n / d)
    for x in 0...w / d
      for y in 0...h / d
        col = bmp.get_pixel(x * d, y * d)
        ret.fill_rect(x * n, y * n, n, n, col)
      end
    end
    return ret
  end
  
  # Enlarge, but Inputs a file instead of another Bitmap
  def self.enlarge_file(file, zoom_x = 1, zoom_y = nil)
    bmp  = self.direct(file)
    return self.enlarge(bmp, zoom_x, zoom_y)
  end
  
  # Places Text On An Empty Bitmap
  # align: 0 is left, 1 is right, 2 is centre
  def self.text(text, hash, bmp = nil, size = nil)
    w     = hash[:W]       || 32
    h     = hash[:H]       || w
    bmp   = self.empty(w, h) unless bmp
    align = hash[:Align]   || 0
    t     = hash[:Outline] || false
    gap   = hash[:Gap]     || 0
    anch  = hash[:Anchor]  || :C
    y_gap = hash[:Y_Gap]   || 16
    x     = align == 2 ? bmp.width / 2 : gap
    y     = 0
    y     = bmp.height / 2 - y_gap / 2 if anch == :C
    x     = hash[:X] if hash[:X]
    y     = hash[:Y] if hash[:Y]
    base  = hash[:Base]   || rad_BASE
    shad  = hash[:Shadow] || rad_SHADOW
    t_pos = [[text, x, y, align, base, shad, t]]
    pbSetSystemFont(bmp)
    bmp.font.size = size if size
    pbDrawTextPositions(bmp, t_pos)
    return bmp
  end
  
  # Puts top bitmap directly on top of bottom
  def self.superimpose(bottom, top)
    # NOTE: LAGGY!
    # Fit Sprites if needed
    if bottom.height > top.height
      top = self.place_on_canvas(top, top.width, bottom.height, :C)
    elsif bottom.height < top.height
      bottom = self.place_on_canvas(bottom, bottom.width, top.height, :C)
    end
    if bottom.width > top.width
      top = self.place_on_canvas(top, bottom.width, top.height, :C)
    elsif bottom.width < top.width
      bottom = self.place_on_canvas(bottom, top.width, bottom.height, :C)
    end
    for x in 0...top.width
      for y in 0...top.height
        next unless top.get_pixel(x, y).alpha > 0
        bottom.blt(x, y, top, Rect.new(x, y, 1, 1))
      end
    end
    return bottom
  end
  
  # (Colour Object used for both)
  # Replaces all pixels of one colour with another colour
  def self.replace_colours(bmp, to_replace, replace_with)
    w   = bmp.width
    h   = bmp.height
    for x in 0...w
      for y in 0...h
        next unless bmp.get_pixel(x, y) == to_replace
        rw = replace_with
        a  = bmp.get_pixel(x, y).alpha
        rw.alpha = a unless rw.alpha == 0
        bmp.fill_rect(x, y, 1, 1, rw)
      end
    end
    return bmp
  end
  
  # (Colour Object used for both)
  # Replaces all pixels of one colour with another colour
  def self.mirror(bmp, dir = :HORIZONTAL)
    w   = bmp.width
    h   = bmp.height
    ret = self.empty(w, h)
    if dir == :HORIZONTAL
      for x in 0...w
        ret.blt(x, 0, bmp, Rect.new(w - x - 1, 0, 1, h))
      end
    else # VERTICAL
      for y in 0...h
        ret.blt(0, y, bmp, Rect.new(0, h - y - 1, w, 1))
      end
    end
    return ret
  end
  
  # Takes a number of bitmaps, and makes them into one
  def self.assemble(array)
    biggest_x = 1
    biggest_y = 1
    # First, determine the size of the canvas
    for hash in array
      bmp = hash[:Bitmap]
      x   = hash[:X] || 0
      y   = hash[:Y] || 0
      biggest_x = [biggest_x, x + bmp.width].max
      biggest_y = [biggest_y, y + bmp.height].max
    end
    ret = self.empty(biggest_x, biggest_y)
    # Now, add the actual bitmaps!
    for hash in array
      bmp = hash[:Bitmap]
      x   = hash[:X] || 0
      y   = hash[:Y] || 0
      ret.blt(x, y, bmp, Rect.new(0, 0, bmp.width, bmp.height))
    end
    return ret
  end
  
  def self.impose(bmp, w, h = nil, anchor = :C)
    h   = w if !h
    o_w = bmp.width
    o_h = bmp.height
    g_w = w - o_w
    g_h = h - o_h
    # Let's do Xs first!
    case anchor
    when :NW, :W, :SW
      x = 0
    when :N,  :C, :S
      x = g_w / 2
    else # :NE, :E, :SE
      x = g_w
    end
    # Now we'll do Ys!
    case anchor
    when :NW, :N, :NE
      y = 0
    when :W,  :C, :E
      y = g_h / 2
    else # :SW, :S, :SE
      y = g_h
    end
    ret = self.empty(w, h)
    ret.blt(x, y, bmp, Rect.new(0, 0, o_w, o_h))
    return ret
  end
  
  def self.hue_change(bmp, hue_change = 0)
    if bmp.is_a?(String)
      bmp = direct(bmp)
    end
    bmp.hue_change(hue_change) if hue_change != 0
    return bmp
  end
end

#=============================================================================
# Saves to PNG
#=============================================================================
class Bitmap
  def save_to_png(filename)
    f = ByteWriter.new(filename)
   
    #============================= Writing header ===============================#
    # PNG signature
    f << [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    # Header length
    f << [0x00, 0x00, 0x00, 0x0D]
    # IHDR
    headertype = [0x49, 0x48, 0x44, 0x52]
    f << headertype
   
    # Width, height, compression, filter, interlacing
    headerdata = ByteWriter.to_bytes(self.width).
      concat(ByteWriter.to_bytes(self.height)).
      concat([0x08, 0x06, 0x00, 0x00, 0x00])
    f << headerdata
   
    # CRC32 checksum
    sum = headertype.concat(headerdata)
    f.write_int Zlib::crc32(sum.pack("C*"))
   
    #============================== Writing data ================================#
    data = []
    for y in 0...self.height
      # Start scanline
      data << 0x00 # Filter: None
      for x in 0...self.width
        px = self.get_pixel(x, y)
        # Write raw RGBA pixels
        data << px.red
        data << px.green
        data << px.blue
        data << px.alpha
      end
    end
    # Zlib deflation
    smoldata = Zlib::Deflate.deflate(data.pack("C*")).bytes
    # data chunk length
    f.write_int smoldata.size
    # IDAT
    f << [0x49, 0x44, 0x41, 0x54]
    f << smoldata
    # CRC32 checksum
    f.write_int Zlib::crc32([0x49, 0x44, 0x41, 0x54].concat(smoldata).pack("C*"))
   
    #============================== End Of File =================================#
    # Empty chunk
    f << [0x00, 0x00, 0x00, 0x00]
    # IEND
    f << [0x49, 0x45, 0x4E, 0x44]
    # CRC32 checksum
    f.write_int Zlib::crc32([0x49, 0x45, 0x4E, 0x44].pack("C*"))
    f.close
    return nil
  end
end

class ByteWriter
  def initialize(filename)
    @file = File.new(filename, "wb")
  end
 
  def <<(*data)
    write(*data)
  end
 
  def write(*data)
    data.each do |e|
      if e.is_a?(Array) || e.is_a?(Enumerator)
        e.each { |item| write(item) }
      elsif e.is_a?(Numeric)
        @file.putc e
      else
        raise "Invalid data for writing.\nData type: #{e.class}\nData: #{e.inspect[0..100]}"
      end
    end
  end
 
  def write_int(int)
    self << ByteWriter.to_bytes(int)
  end
 
  def close
    @file.close
    @file = nil
  end
 
  def self.to_bytes(int)
    return [
      (int >> 24) & 0xFF,
      (int >> 16) & 0xFF,
      (int >> 8) & 0xFF,
       int & 0xFF
    ]
  end
end