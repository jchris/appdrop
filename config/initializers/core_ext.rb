module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module Time #:nodoc:
      # Getting times in different convenient string representations and other objects
      module Conversions
        DATE_FORMATS[:with_time] = "%B %d, %Y at %I:%M%p" # Aug 14 2007 at 12:34:16 PDT
        DATE_FORMATS[:mini] = "%m/%d/%y"
      end
    end
  end
end

module Enumerable
  def uniq_by
    h = {}; inject([]) {|a,x| h[yield(x)] ||= a << x}
  end
end

class Array #:nodoc:
  # given an array of hashes, set each hash's key value to be value
  def store_each(key, value)
    self.each do |i|
      i[key] = value
    end
  end
  
  def histogram
    r = Array.new{|i| 0}
    each do |s| 
      t = yield s
      x = r[t]
      x ||= 0
      r[t] = x + 1
    end
    r
  end
end




class Hash

  def extract *wanted_keys
    result = {}
    wanted_keys.flatten.each do |k|
      result[k] = self[k] if self[k]
    end
    result
  end

  def clear_blank!
    self.keys.each do |key|
      self.delete(key) if self[key].blank?
    end
  end

end

class String
  def normalize
    self.chars.downcase.gsub(/\W/,'')
  end
  def normalize_white
    self.chars.downcase.gsub(/[^\w\s]/,'').gsub(/\W/,' ').squeeze(' ')
  end
  def url_safe
    # st = Iconv.iconv('ascii//ignore//translit','utf-8',self).first
    # st.chars.downcase.gsub(/\W/,'-').squeeze('-')[0...100]
    self.chars.downcase.gsub(/[^a-z0-9]/,'-').squeeze('-')[0...100]
  end
  
  def to_ascii
    # split in muti-byte aware fashion and translate characters over 127
    # and dropping characters not in the translation hash
    self.chars.split('').collect { |c| (c[0] <= 127) ? c : translation_hash[c[0]] }.join
  end
    
  # def to_url_format
  #   url_format = self.to_ascii
  #   url_format = url_format.gsub(/[^A-Za-z0-9]/, '') # all non-word
  #   url_format.downcase!
  #   url_format
  # end
  
  protected
  
    def translation_hash
      @@translation_hash ||= setup_translation_hash  
   
    end
    
    def setup_translation_hash
      # accented_chars   = "ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöøùúûüý".chars.split('')
      # unaccented_chars = "AAAAAACEEEEIIIIDNOOOOOxOUUUUYaaaaaaceeeeiiiinoooooouuuuy".split('')
  
      char_lib = {'ÀÁÂÃÅĀĄĂ' => 'A', 'Ä' => 'Ae', 'àáâãåāąă' => 'a', 'ä' => 'ae', 'Æ' => 'AE', 'æ' => 'ae', 'ÇĆČĈĊ' => 'C', 'çćčĉċ' => 'c', 'ĎĐ' => 'D', 'ďđ' => 'd', 'ÈÉÊËĒĘĚĔĖ' =>'E', 'èéêëēęěĕė' =>'e', 'ƒ' => 'f', 'ĜĞĠĢ' => 'G', 'ĝğġģ' => 'g', 'ĤĦ' => 'H', 'ĥħ' => 'h', 'ÌÍÎÏĪĨĬĮİ' =>'I', 'ìíîïīĩĭįı' =>'i', 'Ĳ' => 'IJ', 'Ĵ' => 'J', 'ĵ' => 'j', 'Ķ' => 'K', 'ķĸ' => 'k', 'ŁĽĹĻĿ' => 'L', 'łľĺļŀ' => 'l', 'ÑŃŇŅŊ' => 'N', 'ñńňņŉŋ' => 'n', 'ÒÓÔÕØŌŐŎ' => 'O', 'Ö' => 'Oe', 'òóôõøōőŏ' => 'o', 'ö' => 'oe', 'Œ' => 'OE', 'œ' => 'oe', 'ŔŘŖ' =>'R', 'ŕřŗ' =>'r', 'ŚŠŞŜȘ' => 'S', 'śšşŝș' => 's', 'ŤŢŦȚ' => 'T', 'ťţŧț' => 't', 'ÙÚÛŪŮŰŬŨŲ' =>'U', 'Ü' => 'Ue', 'ùúûūůűŭũų' =>'u', 'ü' => 'ue', 'Ŵ' => 'W', 'ŵ' => 'w', 'ÝŶŸ' =>'Y', 'ýÿŷ' =>'y', 'ŹŽŻ' =>'Z', 'žżź' =>'z'} 
  
      translation_hash = {}
      char_lib.each do |bads,good|
        bads.chars.split('').each do |bad|
          translation_hash[bad[0]] = good
        end
      end
      # accented_chars.each_with_index { |char, idx| translation_hash[char[0]] = unaccented_chars[idx] }
      # translation_hash["Æ".chars[0]] = 'AE'
      # translation_hash["æ".chars[0]] = 'ae'
      translation_hash
    end


end