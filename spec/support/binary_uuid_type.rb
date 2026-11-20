class BinaryUuidType < ActiveModel::Type::Value
  def type = :binary

  def serialize(value)
    ActiveModel::Type::Binary::Data.new([value.delete("-")].pack("H*")) if value
  end

  def deserialize(value)
    return unless value

    hex = value.to_s.unpack1("H*")
    [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join("-")
  end
end
