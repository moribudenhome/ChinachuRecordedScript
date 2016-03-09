class WolRequests < ActiveRecord::Base
  enum wol_state: %i(requested success pending)

  def wol_request(mac)
    system("sudo ether-wake -b " + mac)
    system("sudo ether-wake -b " + mac)
    system("sudo ether-wake -b " + mac)
    WolRequests.create( :wol_state => WolRequests.wol_states[:requested] )
  end
end