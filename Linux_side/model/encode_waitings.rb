class EncodeWaitings < ActiveRecord::Base
  enum encode_state: %i(wait progress success failure)

  def encode_reservation(src_path, dest_path, program_json)
    EncodeWaitings.create(
    :src_path => src_path, 
    :dst_path => dest_path, 
    :program_data => program_json, 
    :encode_state => EncodeWaitings.encode_states[:wait])
  end
end
