class EncodeWaitings < ActiveRecord::Base
  enum encode_state: %i(wait progress success failure)

  def exists_encode_wait?
    EncodeWaitings.exists?(:encode_state => EncodeWaitings.encode_states[:wait])
  end

  def encode_reservation(src_path, dest_path, program_json)
    EncodeWaitings.create(
    :src_path => src_path, 
    :dst_path => dest_path, 
    :program_data => program_json, 
    :encode_state => EncodeWaitings.encode_states[:wait])
  end
end