function table.is_empty(t)
	return next(t) == nil
end

function table.size(t)
	local elements = 0

	for _ in pairs(t) do
		elements = elements + 1
	end

	return elements
end

if pcall(require, "table.new") then
	function Script.new_array(narr)
		return table.new(narr, 0)
	end

	function Script.new_map(nrec)
		return table.new(0, nrec)
	end

	Script.new_table = table.new
end

function table.clone(t)
	local clone = {}

	for key, value in pairs(t) do
		if value == t then
			clone[key] = clone
		elseif type(value) == "table" then
			clone[key] = table.clone(value)
		else
			clone[key] = value
		end
	end

	return clone
end

function table.clone_instance(t)
	local clone = {}

	for key, value in pairs(t) do
		if value == t then
			clone[key] = clone
		elseif type(value) == "table" then
			clone[key] = table.clone_instance(value)
		else
			clone[key] = value
		end
	end

	setmetatable(clone, getmetatable(t))

	return clone
end

function table.shallow_copy(t)
	local copy = {}

	for key, value in pairs(t) do
		copy[key] = value
	end

	return copy
end

function table.crop(t, index)
	local new_table = {}
	local new_table_size = 0

	for idx = index, #t do
		new_table_size = new_table_size + 1
		new_table[new_table_size] = t[idx]
	end

	return new_table, new_table_size
end

function table.create_copy(copy, original)
	if not copy then
		return table.clone(original)
	else
		for key, value in pairs(original) do
			if value == original then
				copy[key] = copy
			elseif type(value) == "table" then
				copy[key] = table.create_copy(copy[key], value)
			else
				copy[key] = value
			end
		end

		for key, _ in pairs(copy) do
			if original[key] == nil then
				copy[key] = nil
			end
		end

		return copy
	end
end

function table.create_copy_instance(copy, original)
	if not copy then
		return table.clone_instance(original)
	else
		setmetatable(copy, getmetatable(original))

		for key, value in pairs(original) do
			if value == original then
				copy[key] = copy
			elseif type(value) == "table" then
				copy[key] = table.create_copy_instance(copy[key], value)
			else
				copy[key] = value
			end
		end

		for key, _ in pairs(copy) do
			if original[key] == nil then
				copy[key] = nil
			end
		end

		return copy
	end
end

function table.merge(dest, source)
	for key, value in pairs(source) do
		dest[key] = value
	end

	return dest
end

function table.merge_array(dest, source)
	for i = 1, #source do
		dest[i] = source[i]
	end

	return dest
end

function table.compact_array(t)
	local p = 0

	for k, v in pairs(t) do
		if v then
			p = p + 1
		end
	end

	local i = 1
	local k = 1

	while p >= k do
		if t[i] then
			t[k] = t[i]
			t[i] = k == i and t[i] or nil
			k = k + 1
		end

		i = i + 1
	end

	return t
end

function table.filter(t, func)
	local copy = {}

	for k, v in pairs(t) do
		if func(v) then
			copy[k] = v
		end
	end

	return copy
end

function table.add_missing(dest, source)
	for key, value in pairs(source) do
		if dest[key] == nil then
			dest[key] = value
		end
	end

	return dest
end

function table.merge_recursive(dest, source)
	for key, value in pairs(source) do
		local is_table = type(value) == "table"

		if value == source then
			dest[key] = dest
		elseif is_table and type(dest[key]) == "table" then
			table.merge_recursive(dest[key], value)
		elseif is_table then
			dest[key] = table.clone(value)
		else
			dest[key] = value
		end
	end

	return dest
end

function table.append(dest, source)
	local dest_size = #dest

	for i = 1, #source do
		dest_size = dest_size + 1
		dest[dest_size] = source[i]
	end

	return dest
end

function table.append_non_indexed(dest, source)
	local dest_size = #dest

	for _, value in pairs(source) do
		dest_size = dest_size + 1
		dest[dest_size] = value
	end
end

function table.array_contains(t, element)
	for i = 1, #t do
		if t[i] == element then
			return true
		end
	end

	return false
end

function table.contains(t, element)
	for _, value in pairs(t) do
		if value == element then
			return true
		end
	end

	return false
end

function table.has_intersection(t1, t2)
	for _, v1 in pairs(t1) do
		for _, v2 in pairs(t2) do
			if v1 == v2 then
				return true
			end
		end
	end

	return false
end

function table.find(t, element)
	for key, value in pairs(t) do
		if value == element then
			return key
		end
	end
end

function table.find_by_key(t, search_key, search_value)
	for key, value in pairs(t) do
		if value[search_key] == search_value then
			return key, value
		end
	end

	return nil
end

function table.index_of(t, element)
	for i = 1, #t do
		if t[i] == element then
			return i
		end
	end

	return -1
end

function table.slice(t, start_index, length)
	local end_index = math.min(start_index + length - 1, #t)
	local slice = {}

	for i = start_index, end_index do
		slice[i - start_index + 1] = t[i]
	end

	return slice
end

function table.sorted(t, keys, order_func)
	for k, _ in pairs(t) do
		keys[#keys + 1] = k
	end

	if order_func then
		table.sort(keys, function (a, b)
			return order_func(t, a, b)
		end)
	else
		table.sort(keys)
	end

	local i = 0

	return function ()
		i = i + 1

		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

function table.reverse(t)
	local size = #t

	for i = 1, math.floor(size / 2) do
		t[size - i + 1] = t[i]
		t[i] = t[size - i + 1]
	end
end

if not pcall(require, "table.clear") then
	function table.clear(t)
		for key in pairs(t) do
			t[key] = nil
		end
	end
end

function table.clear_array(t, n)
	for i = 1, n do
		t[i] = nil
	end
end

local function _table_dump(key, value, depth, max_depth, print_func)
	if max_depth < depth then
		return
	end

	local prefix = string.rep("  ", depth) .. "[" .. tostring(key) .. "]"

	if type(value) == "table" then
		prefix = prefix .. " = "

		print_func(prefix .. "table")

		if max_depth then
			for k, v in pairs(value) do
				_table_dump(k, v, depth + 1, max_depth, print_func)
			end
		end

		local meta = getmetatable(value)

		if meta then
			print_func(prefix .. "metatable")

			if max_depth then
				for k, v in pairs(meta) do
					if key ~= "__index" and key ~= "super" then
						_table_dump(k, v, depth + 1, max_depth, print_func)
					end
				end
			end
		end
	elseif type(value) == "function" or type(value) == "thread" or type(value) == "userdata" or value == nil then
		print_func(prefix .. " = " .. tostring(value))
	else
		print_func(prefix .. " = " .. tostring(value) .. " (" .. type(value) .. ")")
	end
end

function table.dump(t, tag, max_depth, print_func)
	print_func = print_func or print

	if tag then
		print_func(string.format("<%s>", tag))
	end

	for key, value in pairs(t) do
		_table_dump(key, value, 0, max_depth or 0, print_func)
	end

	if tag then
		print_func(string.format("</%s>", tag))
	end
end

local _value_to_string_array, _table_tostring_array = nil

function _value_to_string_array(v, depth, max_depth, skip_private)
	if type(v) == "table" then
		if depth < max_depth then
			return _table_tostring_array(v, depth + 1, max_depth, skip_private)
		else
			return {
				"(rec-limit)"
			}
		end
	elseif type(v) == "string" then
		return {
			"\"",
			v,
			"\""
		}
	else
		return {
			tostring(v)
		}
	end
end

function _table_tostring_array(t, depth, max_depth, skip_private)
	local str = {
		"{\n"
	}
	local last_tabs = string.rep("\t", depth - 1)
	local tabs = last_tabs .. "\t"
	local len = #t

	for i = 1, len do
		str[#str + 1] = tabs

		table.append(str, _value_to_string_array(t[i], depth, max_depth, skip_private))

		str[#str + 1] = ",\n"
	end

	for key, value in pairs(t) do
		local is_number = type(key) == "number"

		if (is_number or not skip_private or key:sub(1, 1) ~= "_") and (not is_number or key < 1 or len < key) then
			local key_str = nil

			if is_number then
				key_str = string.format("[%i]", key)
			else
				key_str = tostring(key)
			end

			str[#str + 1] = tabs
			str[#str + 1] = key_str
			str[#str + 1] = " = "

			table.append(str, _value_to_string_array(value, depth, max_depth, skip_private))

			str[#str + 1] = ",\n"
		end
	end

	str[#str + 1] = last_tabs
	str[#str + 1] = "}"

	return str
end

function table.tostring(t, max_depth, skip_private)
	return table.concat(_table_tostring_array(t, 1, max_depth or 1, skip_private))
end

function table.shuffle(source, seed)
	if seed then
		for ii = #source, 2, -1 do
			local swap = nil
			seed, swap = math.next_random(seed, ii)
			source[ii] = source[swap]
			source[swap] = source[ii]
		end
	else
		for ii = #source, 2, -1 do
			local swap = math.random(ii)
			source[ii] = source[swap]
			source[swap] = source[ii]
		end
	end

	return seed
end

function table.max(t)
	local max_key, max_value = next(t)

	for key, value in pairs(t) do
		if max_value < value then
			max_value = value
			max_key = key
		end
	end

	return max_key, max_value
end

function table.reduce(t, f, e)
	for _, value in pairs(t) do
		e = f(e, value)
	end

	return e
end

function table.for_each(t, f)
	for key, value in pairs(t) do
		t[key] = f(value)
	end
end

local random_indices = {}
local all = {}

function table.get_random_array_indices(size, num_picks)
	for i = 1, size do
		all[i] = i
	end

	for i = 1, num_picks do
		local random_index = math.random(1, size)
		random_indices[i] = all[random_index]
		all[random_index] = all[size]
		size = size - 1
	end

	return random_indices
end

function table.set(list, destination)
	local set = destination or {}

	for _, l in ipairs(list) do
		set[l] = true
	end

	return set
end

function table.mirror_table(source, dest)
	local result = dest or {}

	for k, v in pairs(source) do
		result[k] = v
		result[v] = k
	end

	return result
end

function table.mirror_array(source, dest)
	local result = dest or {}

	for index, value in ipairs(source) do
		result[index] = value
		result[value] = index
	end

	return result
end

function table.add_mirrored_entry(list, a, b)
	list[a] = b
	list[b] = a
end

function table.mirror_array_inplace(t)
	for i = 1, #t do
		local value = t[i]
		t[value] = i
	end

	return t
end

function table.keys(t, output)
	local n = 0
	local result = output or {}

	for key, _ in pairs(t) do
		n = n + 1
		result[n] = key
	end

	return result
end

function table.values(t, output)
	local n = 0
	local result = output or {}

	for _, value in pairs(t) do
		n = n + 1
		result[n] = value
	end

	return result
end

function table.append_varargs(t, ...)
	local num_varargs = select("#", ...)
	local t_size = #t

	for i = 1, num_varargs do
		t[t_size + i] = select(i, ...)
	end

	return t
end

function table.merge_varargs(args, num_args, ...)
	local merged = {
		unpack(args, 1, num_args)
	}
	local num_varargs = select("#", ...)

	for i = 1, num_varargs do
		merged[num_args + i] = select(i, ...)
	end

	return merged, num_args + num_varargs
end

function table.pack(...)
	return {
		...
	}, select("#", ...)
end

function table.array_to_table(array, array_n, out_table)
	for i = 1, array_n, 2 do
		local key = array[i]
		local value = array[i + 1]
		out_table[key] = value
	end
end

function table.table_to_array(t, array_out, values_only)
	local array_out_n = 0

	for key, value in pairs(t) do
		if not values_only then
			array_out[array_out_n + 1] = key
			array_out[array_out_n + 2] = value
			array_out_n = array_out_n + 2
		else
			array_out[array_out_n + 1] = value
			array_out_n = array_out_n + 1
		end
	end

	return array_out_n
end

function table.add_meta_logging(real_table, debug_enabled, debug_name)
	real_table = real_table or {}

	if debug_enabled then
		local front_table = {
			__index = function (table, key)
				local value = rawget(real_table, key)

				print("meta getting", debug_name, key, value)

				return value
			end
		}

		setmetatable(front_table, front_table)

		function front_table.__newindex(table, key, value)
			print("meta setting", debug_name, key, value)
			rawset(real_table, key, value)
		end

		return front_table
	else
		return real_table
	end
end

local function ripairs_it(t, i)
	i = i - 1
	local v = t[i]

	if v ~= nil then
		return i, v
	end
end

function ripairs(t)
	return ripairs_it, t, #t + 1
end

function upairs(t)
	return next, t.__data, nil
end

function table.swap_delete(t, index)
	local table_length = #t
	t[index] = t[table_length]
	t[table_length] = nil
end

function table.set_readonly(table)
	return setmetatable({}, {
		__metatable = false,
		__index = table,
		__newindex = function (_, key, value)
			error("Attempt to modify read-only table")
		end
	})
end

function table.remove_sequence(t, from, to)
	local length = #t
	local num_remove = to - from + 1

	for i = 0, length - to do
		t[from + i] = t[to + 1 + i]
	end

	for i = length - num_remove + 1, length do
		t[i] = nil
	end
end

local _enum_index_metatable = {
	__index = function (_, k)
		return error("Don't know `" .. tostring(k) .. "` for enum.")
	end
}

function table.enum(...)
	local t = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)
		t[v] = v
	end

	setmetatable(t, _enum_index_metatable)

	return t
end

local _lookup_index_metatable = {
	__index = function (_, k)
		return error("Don't know `" .. tostring(k) .. "` for lookup.")
	end
}

function table.index_lookup_table(...)
	local t = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)
		t[v] = i
		t[i] = v
	end

	setmetatable(t, _lookup_index_metatable)

	return t
end

function table.make_unique(t)
	t.__data = {}
	local metatable = {
		__index = function (t, k)
			return rawget(t.__data, k)
		end,
		__newindex = function (t, k, v)
			local data = rawget(t, "__data")
			data[k] = v
		end
	}

	setmetatable(t, metatable)
end

function table.make_strict(table, name, optional_error_message__index, optional_error_message__newindex)
	local __index_err_msg = optional_error_message__index or ""
	local __newindex_err_msg = optional_error_message__newindex or ""
	local metatable = {
		__index = function (_, field_name)
			ferror("Table %q does not have field_name %q defined. %s", name, field_name, __index_err_msg)
		end,
		__newindex = function ()
			ferror("Table %q is strict. Not allowed to add new fields. %s", name, __newindex_err_msg)
		end
	}

	setmetatable(table, metatable)
end

function table.make_strict_with_interface(t, name, interface)
	local valid_keys = {}

	for i = 1, #interface do
		local field_name = interface[i]
		valid_keys[field_name] = true
	end

	return setmetatable(t, {
		__index = function (t, key)
			return nil
		end,
		__newindex = function (t, key, val)
			return rawset(t, key, val)
		end
	})
end

function table.verify_schema(t, name, schema)
	for key, _ in pairs(schema) do
		if t[key] == nil then
			Log.warning("SchemaVerifier", "Tried to verify %q, but it's not matching the schema", name)
			table.dump(t, name)
			table.dump(schema, "schema")

			return false
		end
	end

	for key, _ in pairs(t) do
		if schema[key] == nil then
			Log.warning("SchemaVerifier", "Tried to verify %q, but it's not matching the schema", name)
			table.dump(t, name)
			table.dump(schema, "schema")

			return false
		end
	end

	return true
end

function table.make_locked(original_t, optional_error_message)
	local locked_table = {
		__locked = true,
		__data = original_t
	}
	local error_msg = optional_error_message or "Table is locked."

	return setmetatable(locked_table, {
		__index = function (t, key)
			t.__locked = true

			return rawget(t.__data, key)
		end,
		__newindex = function (t, key, val)
			t.__locked = true
			local data = rawget(t, "__data")
			data[key] = val
		end
	})
end

StrictNil = StrictNil or {}

function table.make_strict_nil_exceptions(t)
	local declared_args = {}

	for k, v in pairs(t) do
		declared_args[k] = true

		if v == StrictNil then
			t[k] = nil
		end
	end

	local meta = {
		__declared = declared_args
	}

	function meta.__newindex(t, k, v)
		if meta.__declared[k] then
			rawset(t, k, v)
		else
			ferror("Table is strict. Not allowed to add new fields.")
		end
	end

	function meta.__index(t, k)
		if not meta.__declared[k] then
			ferror("Table does not have field_name %q defined.", k)
		end
	end

	setmetatable(t, meta)

	return t
end

function table.make_strict_readonly(data, name, optional_interface, optional_error_message_interface, optional_error_message__index, optional_error_message__newindex)
	local interface = nil

	if optional_interface then
		interface = {}

		for i = 1, #optional_interface do
			local field_name = optional_interface[i]
			interface[field_name] = true
		end

		local error_msg = optional_error_message_interface or ""

		for field_name, field in pairs(data) do
			-- Nothing
		end
	end

	local strict_readonly_t = {
		__data = data,
		__interface = interface
	}
	local __index_error_msg = optional_error_message__index or ""
	local __newindex_error_msg = optional_error_message__newindex or ""
	local metatable = {
		__index = function (t, field_name)
			local __interface = rawget(t, "__interface")

			if __interface then
				local valid_field = __interface[field_name]

				return rawget(t.__data, field_name)
			else
				local field = rawget(t.__data, field_name)

				return field
			end
		end,
		__newindex = function (t, field_name, value)
			ferror("Table %q is readonly.%s", name, __newindex_error_msg)
		end
	}

	setmetatable(strict_readonly_t, metatable)

	return strict_readonly_t
end

local TEMP_CHECKED_VALUES = {}

function table.unique_array_values(t, destination)
	local result = destination or {}
	local next_index = 1

	for i = 1, #t do
		local value = t[i]

		if not TEMP_CHECKED_VALUES[value] then
			result[next_index] = value
			next_index = next_index + 1
			TEMP_CHECKED_VALUES[value] = true
		end
	end

	table.clear(TEMP_CHECKED_VALUES)

	return result
end

local random_indexed_meta = {
	__index = function (_, i)
		return i
	end
}

function table.generate_random_table(from, to, seed)
	local result = {}
	local temp = setmetatable({}, random_indexed_meta)
	local last_seed = seed

	for iter = 1, to do
		local index = nil

		if last_seed then
			local new_seed, rnd = math.next_random(last_seed, from, to)
			index = rnd
			last_seed = new_seed
		else
			index = math.random(from, to)
		end

		local val = temp[index]
		temp[index] = temp[from]
		result[iter] = val
		from = from + 1
	end

	return result, last_seed
end

function table.remove_empty_values(t)
	if table.is_empty(t) then
		return nil
	end

	local result = {}

	for k, v in pairs(t) do
		if k ~= StrictNil then
			local value_type = type(v)

			if value_type == "table" then
				if not table.is_empty(v) then
					result[k] = table.remove_empty_values(v)
				end
			elseif value_type == "string" and v ~= "" then
				result[k] = v
			elseif value_type ~= "nil" then
				result[k] = v
			end
		end
	end

	if table.is_empty(result) then
		return nil
	else
		return result
	end
end

function table.array_remove_if(t, predicate)
	local i = 1
	local v = nil

	for j = 1, #t do
		t[j] = nil
		v = t[j]

		if not predicate(v) then
			i = i + 1
			t[i] = v
		end
	end
end

function table.sum(t)
	local s = 0

	for _, elem in pairs(t) do
		s = s + elem
	end

	return s
end

function table.average(t)
	return table.sum(t) / #t
end

function table.percentile(t, p)
	return t[math.round(p / 100 * #t)]
end

function table.variance(t)
	local avg = table.average(t)
	local diff = {}

	for i, v in pairs(t) do
		diff[i] = (v - avg)^2
	end

	return table.average(diff)
end
