local Graph = class("Graph")

function Graph:init()
	self._nodes = {}
end

function Graph:clear_nodes()
	local nodes = self._nodes

	table.clear(nodes)
end

function Graph:add_node(value)
	local nodes = self._nodes

	if not nodes[value] then
		nodes[value] = {
			adjacency_nodes = {}
		}
	end
end

function Graph:add_edge(value_1, value_2, edge_is_undiracted)
	local nodes = self._nodes

	if nodes[value_1] and not edge_is_undiracted or nodes[value_1] and nodes[value_2] then
		local adjacency_nodes = nodes[value_1].adjacency_nodes
		adjacency_nodes[#adjacency_nodes + 1] = value_2

		if edge_is_undiracted then
			adjacency_nodes = nodes[value_2].adjacency_nodes
			adjacency_nodes[#adjacency_nodes + 1] = value_1
		end
	end
end

function Graph:get_adjacency_nodes(value)
	local nodes = self._nodes
	local return_value = nil

	if nodes[value] then
		local adjacency_nodes = nodes[value].adjacency_nodes

		if #adjacency_nodes > 0 then
			return_value = adjacency_nodes
		end
	end

	return return_value
end

function Graph:has_adjacency_nodes(value)
	local nodes = self._nodes

	if nodes[value] then
		local adjacency_nodes = nodes[value].adjacency_nodes

		if #adjacency_nodes > 0 then
			return true
		end
	end

	return false
end

return Graph
