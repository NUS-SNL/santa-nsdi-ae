santa = Proto("Santa", "Santa Protocol")
f = santa.fields
f.q_num = ProtoField.uint8("santa.q_num", "Queue Number", base.DEC)
f.q_depth = ProtoField.uint24("santa.q_depth", "Queue Depth", base.DEC)

-- Dissect function to parse each packet
function santa.dissector(buffer, pinfo, tree)
    -- Check the buffer size to ensure it's large enough for our fields
    --if buffer:len() < 4 then return end
    -- Check if the packet is marked as a retransmission or out-of-order
    local is_retransmission = pinfo.private.tcp_analysis and pinfo.private.tcp_analysis.retransmission
    local is_out_of_order = pinfo.private.tcp_analysis and pinfo.private.tcp_analysis.out_of_order

    if is_retransmission then
        -- Add the protocol to the dissection display tree
        local subtree = tree:add(santa, buffer(), "Santa Protocol Data")
        subtree:add(f.q_num, buffer(0,1))
        subtree:add(f.q_depth, buffer(1,3))

        -- Update the info column to show our protocol is present
        pinfo.cols.protocol = santa.name
    end

    if is_out_of_order then
        -- Add the protocol to the dissection display tree
        local subtree = tree:add(santa, buffer(), "Santa Protocol Data")
        subtree:add(f.q_num, buffer(0,1))
        subtree:add(f.q_depth, buffer(1,3))

        -- Update the info column to show our protocol is present
        pinfo.cols.protocol = santa.name
    end

    -- Add the protocol to the dissection display tree
    local subtree = tree:add(santa, buffer(), "Santa Protocol Data")
    subtree:add(f.q_num, buffer(0,1))
    subtree:add(f.q_depth, buffer(1,3))

    -- Update the info column to show our protocol is present
    pinfo.cols.protocol = santa.name
end

-- Register the dissector to be called for TCP packets (assuming standard TCP port usage)
-- If your protocol uses a specific port, replace 'tcp' with the port number
--tcp_dissector_table:add_for_decode_as(santa)
-- Register the dissector to be called for TCP packets on specific ports
tcp_dissector_table = DissectorTable.get("tcp.port")
local ports = {11000, 6000, 11001, 6001, 10000, 5000, 10001, 5001, 12000, 7000, 12001, 7001, 13000, 8000, 13001, 8001}
for _, port in ipairs(ports) do
    tcp_dissector_table:add(port, santa)
end

