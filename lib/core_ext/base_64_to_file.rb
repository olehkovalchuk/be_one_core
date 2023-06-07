module Base64ToFile
  module_function
  def base64_to_file(base64_data, filename=nil)
    return base64_data unless base64_data.is_a? String
    
    start_regex = /data:image\/[a-z]{3,4};base64,/
    filename ||= SecureRandom.hex

    regex_result = start_regex.match(base64_data)
    if base64_data && regex_result
      start = regex_result.to_s
      tempfile = Tempfile.new(filename)
      tempfile.binmode
      tempfile.write(Base64.decode64(base64_data[start.length..-1]))
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        :tempfile => tempfile,
        :filename => "#{filename}.jpg",
        :original_filename => "#{filename}.jpg"
      )

      uploaded_file
    else
      nil
    end
  end

end