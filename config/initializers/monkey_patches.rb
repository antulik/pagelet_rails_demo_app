#
# class Dir
#   def self.new_get *args
#     puts "====================="
#     puts args.inspect
#     r = nil
#     ms = Benchmark.ms {
#       r = old_get *args
#     }
#
#     s = '/Users/anton/Dropbox/projects/rails5/app/pagelets/home_blocks/views/remote_true{.en,}{.js,.application/ecmascript,.application/x-ecmascript,.html,.text,.css,.ics,.csv,.vcf,.png,.jpeg,.gif,.bmp,.tiff,.svg,.mpeg,.xml,.rss,.atom,.yaml,.multipart_form,.url_encoded_form,.json,.pdf,.zip,.gzip,}{}{.raw,.erb,.html,.builder,.ruby,.coffee,.slim,.jbuilder,}'
#
#     if args.first == s
#       # binding.pry
#     end
#
#     puts ms
#     # puts caller(1)
#     r
#   end
#
#   class << self
#     alias_method :old_get, :[]
#     alias_method :[], :new_get
#   end
# end
