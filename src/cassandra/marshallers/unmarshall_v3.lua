local marshall_v3 = require "cassandra.marshallers.marshall_v3"
local unmarshall_v2 = require "cassandra.marshallers.unmarshall_v2"

local _M = {}

for k, v in pairs(unmarshall_v2) do
  _M[k] = v
end

-- Extend

function _M.read_list(bytes, type)
  local element_type = type.value
  local buffer = _M.create_buffer(bytes)
  local n = _M.read_int(buffer)
  local elements = {}
  for _ = 1, n do
    elements[#elements + 1] = _M.read_value(buffer, element_type)
  end
  return elements
end

function _M.read_map(bytes, type)
  local key_type = type.value[1]
  local value_type = type.value[2]
  local buffer = _M.create_buffer(bytes)
  local n = _M.read_int(buffer)
  local map = {}
  for _ = 1, n do
    local key = _M.read_value(buffer, key_type)
    local value = _M.read_value(buffer, value_type)
    map[key] = value
  end
  return map
end

function _M.read_udt(bytes, type)
  local udt = {}
  local buffer = _M.create_buffer(bytes)
  for _, field in ipairs(type.fields) do
    local value = _M.read_value(buffer, field.type)
    udt[field.name] = value
  end
  return udt
end

function _M.read_tuple(bytes, type)
  local tuple = {}
  local buffer = _M.create_buffer(bytes)
  for _, field in ipairs(type.fields) do
    tuple[#tuple + 1] = _M.read_value(buffer, field.type)
  end
  return tuple
end

_M.decoders[marshall_v3.TYPES.udt]   = _M.read_udt
_M.decoders[marshall_v3.TYPES.tuple] = _M.read_tuple

function _M.read_value(buffer, type)
  local bytes = _M.read_bytes(buffer)
  if bytes == nil then
    return nil
  end

  return _M.decoders[type.id](bytes, type)
end

return _M