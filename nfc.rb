
require 'ruby-nfc'
class Rfid
    # get all readers available with ruby-nfc gem
    @@readers = NFC::Reader.all
  

    # returns UID in hex format
    def read_uid
		@@readers[0].poll(Mifare::Classic::Tag) do |tag|
		begin 
			uid = tag.uid_hex
			return uid 
		end
		end
	end
end

if __FILE__ == $0
    rf = Rfid.new
    puts "Siusplau apropeu la targeta al lector"
    uid = rf.read_uid
    puts uid
end
