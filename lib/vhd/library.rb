class Vhd::Library
  VALID_TYPES = [:fixed]

  attr_reader :name, :footer, :size

  def initialize(options={})
    raise "Invalid vhd type" unless VALID_TYPES.include?(options[:type])
    raise "Name is required" unless options[:name]
    raise "Size is required" unless options[:size]
    @name   = options[:name]
    @footer = {}
    @size   = options[:size]

    self.generate_footer
  end

  def create
    binding.pry
    File.open(@name, "wb") { |f| f.puts @footer.values.join }
  end

  def generate_footer(options={})
    @footer[:cookie]       = "conectix".force_encoding("BINARY")
    @footer[:features]     = Array(options[:features] || "00000002").pack("H*")
    @footer[:ff]           = Array(options[:file_format] || "00010000").pack("H*")
    @footer[:offset]       = Array(options[:data_offset] || "FFFFFFFFFFFFFFFF").pack("H*")
    #@footer[:time]         = (Time.now - Time.parse("Jan 1, 2000 12:00:00 AM GMT")).to_i.to_s(16)
    @footer[:time]         = [(Time.parse("Jan 23, 2014 13:00:00 PM -0500") - Time.parse("Jan 1, 2000 12:00:00 AM GMT")).to_i.to_s(16)].pack("H*")
    #@footer[:creator_app]  = "rvhd"
    @footer[:creator_app]  = "win ".force_encoding("UTF-8")
    @footer[:creator_ver]  = ["00060002"].pack("H*")
    @footer[:creator_host] = "Wi2k".force_encoding("UTF-8")
    @footer[:orig_size]    = size_in_hex
    @footer[:curr_size]    = size_in_hex
    @footer[:geometry]     = self.geometry
    @footer[:disk_type]    = ["00000002"].pack("H*")
    @footer[:checksum]     = ""
    uuid = "aba637a999a2498f6edfd01dd854021d" # SecureRandom.hex
    @footer[:uuid]         = uuid.scan(/../).map { |c| c.hex.chr.force_encoding("BINARY") }.join
    @footer[:state]        = ["0"].pack("H*")
    @footer[:reserved]     = Array("00"*427).pack("H*")

    self.checksum
  end

  def size_in_bytes
    (((@size * 1024) * 1024) * 1024).to_i
  end

  def size_in_hex
    hex_size = size_in_bytes.to_s(16)
    hex_size = "0" + hex_size until hex_size.length == 16
    [hex_size].pack("H*")
  end

  def geometry
    max_size      = 65535 * 16 * 255 * 512
    capacity      = size_in_bytes > max_size ? max_size : size_in_bytes
    total_sectors = capacity / 512

    if total_sectors > (65535 * 16 * 63)
      sectors_per_track  = 255
      heads_per_cylinder = 16
    else
      sectors_per_track     = 17
      cylinders_times_heads = total_sectors / sectors_per_track
      heads_per_cylinder    = (cylinders_times_heads + 1023) / 1024
      heads_per_cylinder    = 4 if heads_per_cylinder < 4

      cylinders_times_heads >= ((heads_per_cylinder * 1024) or (heads_per_cylinder > 16))
      sectors_per_track  = 63
      heads_per_cylinder = 16
    end

    cylinders = (total_sectors / sectors_per_track) / heads_per_cylinder

    [cylinders, heads_per_cylinder, sectors_per_track].pack("SCC")
  end

  def checksum
    checksum = 0
    @footer.each do |k,v|
      if k != :checksum
        value = v.reverse.codepoints.each_with_index.inject(0) { |x,(y,z)| x + y * (256 ** z) }
        ap "#{k}: #{value}"
        checksum += value
      end
    end

    # this ends up 16 bytes long when it should only be 4.  I think this is the last thing keeping the vhd from being valid
    @footer[:checksum] = [checksum.to_s(16)].pack("H*")
  end
end
