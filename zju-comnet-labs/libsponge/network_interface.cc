#include "network_interface.hh"

#include "arp_message.hh"
#include "ethernet_frame.hh"

#include <iostream>

using namespace std;

//! \param[in] ethernet_address Ethernet (what ARP calls "hardware") address of the interface
//! \param[in] ip_address IP (what ARP calls "protocol") address of the interface
NetworkInterface::NetworkInterface(const EthernetAddress &ethernet_address, const Address &ip_address)
    : _ethernet_address(ethernet_address), _ip_address(ip_address) {
    cerr << "DEBUG: Network interface has Ethernet address " << to_string(_ethernet_address) << " and IP address "
         << ip_address.ip() << "\n";
}

//! \param[in] dgram the IPv4 datagram to be sent
//! \param[in] next_hop the IP address of the interface to send it to (typically a router or default gateway, but may also be another host if directly connected to the same network as the destination)
//! (Note: the Address type can be converted to a uint32_t (raw 32-bit IP address) with the Address::ipv4_numeric() method.)
void NetworkInterface::send_datagram(const InternetDatagram &dgram, const Address &next_hop) {
    // convert IP address of next hop to raw 32-bit representation (used in ARP header)
    const uint32_t next_hop_ip = next_hop.ipv4_numeric();

    // Check if the Ethernet address is already in the ARP cache
    auto arp_it = _arp_cache.find(next_hop_ip);
    if (arp_it != _arp_cache.end()) {
        // Ethernet address is known, send the frame immediately
        EthernetFrame frame;
        frame.header().dst = arp_it->second.first;        // Destination MAC address
        frame.header().src = _ethernet_address;           // Source MAC address
        frame.header().type = EthernetHeader::TYPE_IPv4;  // IPv4 type
        frame.payload() = dgram.serialize();              // Serialize the datagram as payload
        _frames_out.push(frame);
    } else {
        // Ethernet address is unknown, queue the datagram
        _pending_datagrams[next_hop_ip].push(dgram);

        // Check if we've already sent an ARP request for this IP recently
        auto arp_req_it = _arp_requests.find(next_hop_ip);
        if (arp_req_it == _arp_requests.end()) {
            // No recent ARP request, send a new one
            ARPMessage arp_request;
            arp_request.opcode = ARPMessage::OPCODE_REQUEST;
            arp_request.sender_ethernet_address = _ethernet_address;
            arp_request.sender_ip_address = _ip_address.ipv4_numeric();
            arp_request.target_ethernet_address = {0, 0, 0, 0, 0, 0};  // Unknown
            arp_request.target_ip_address = next_hop_ip;

            // Encapsulate ARP request in Ethernet frame and broadcast
            EthernetFrame frame;
            frame.header().dst = ETHERNET_BROADCAST;  // Broadcast address
            frame.header().src = _ethernet_address;
            frame.header().type = EthernetHeader::TYPE_ARP;
            frame.payload() = BufferList(arp_request.serialize());
            _frames_out.push(frame);

            // Record the ARP request time
            _arp_requests[next_hop_ip] = ARP_REQUEST_TIMEOUT;
        }
    }
}

//! \param[in] frame the incoming Ethernet frame
optional<InternetDatagram> NetworkInterface::recv_frame(const EthernetFrame &frame) {
    // Check if the frame is intended for this interface (or is a broadcast)
    const EthernetAddress &dst = frame.header().dst;
    if (dst != _ethernet_address && dst != ETHERNET_BROADCAST) {
        // Frame is not for us, discard it
        return {};
    }

    // Handle IPv4 datagram
    if (frame.header().type == EthernetHeader::TYPE_IPv4) {
        InternetDatagram dgram;
        if (dgram.parse(frame.payload()) == ParseResult::NoError) {
            return dgram;
        }
    }
    // Handle ARP message
    else if (frame.header().type == EthernetHeader::TYPE_ARP) {
        ARPMessage arp_msg;
        if (arp_msg.parse(frame.payload()) == ParseResult::NoError) {
            // Learn the mapping from sender IP to sender Ethernet address
            const uint32_t sender_ip = arp_msg.sender_ip_address;
            const EthernetAddress sender_eth = arp_msg.sender_ethernet_address;

            // Add to ARP cache with 30-second timeout
            _arp_cache[sender_ip] = {sender_eth, ARP_CACHE_TIMEOUT};

            // If this is an ARP request for our IP address, send a reply
            if (arp_msg.opcode == ARPMessage::OPCODE_REQUEST &&
                arp_msg.target_ip_address == _ip_address.ipv4_numeric()) {
                // Create ARP reply
                ARPMessage arp_reply;
                arp_reply.opcode = ARPMessage::OPCODE_REPLY;
                arp_reply.sender_ethernet_address = _ethernet_address;
                arp_reply.sender_ip_address = _ip_address.ipv4_numeric();
                arp_reply.target_ethernet_address = sender_eth;
                arp_reply.target_ip_address = sender_ip;

                // Encapsulate in Ethernet frame
                EthernetFrame reply_frame;
                reply_frame.header().dst = sender_eth;
                reply_frame.header().src = _ethernet_address;
                reply_frame.header().type = EthernetHeader::TYPE_ARP;
                reply_frame.payload() = BufferList(arp_reply.serialize());
                _frames_out.push(reply_frame);
            }
            // If this is an ARP reply, send any pending datagrams
            else if (arp_msg.opcode == ARPMessage::OPCODE_REPLY) {
                // Remove the ARP request record
                _arp_requests.erase(sender_ip);

                // Send all pending datagrams for this IP
                auto pending_it = _pending_datagrams.find(sender_ip);
                if (pending_it != _pending_datagrams.end()) {
                    while (!pending_it->second.empty()) {
                        const InternetDatagram &dgram = pending_it->second.front();

                        // Create and send the frame
                        EthernetFrame eth_frame;
                        eth_frame.header().dst = sender_eth;
                        eth_frame.header().src = _ethernet_address;
                        eth_frame.header().type = EthernetHeader::TYPE_IPv4;
                        eth_frame.payload() = dgram.serialize();
                        _frames_out.push(eth_frame);

                        pending_it->second.pop();
                    }
                    // Remove the empty queue
                    _pending_datagrams.erase(pending_it);
                }
            }
        }
    }

    return {};
}

//! \param[in] ms_since_last_tick the number of milliseconds since the last call to this method
void NetworkInterface::tick(const size_t ms_since_last_tick) {
    // Update ARP cache entries and remove expired ones
    for (auto it = _arp_cache.begin(); it != _arp_cache.end();) {
        if (it->second.second <= ms_since_last_tick) {
            // Entry has expired, remove it
            it = _arp_cache.erase(it);
        } else {
            // Decrement remaining time
            it->second.second -= ms_since_last_tick;
            ++it;
        }
    }

    // Update ARP request timers and remove expired ones
    for (auto it = _arp_requests.begin(); it != _arp_requests.end();) {
        if (it->second <= ms_since_last_tick) {
            // ARP request has expired, remove it (will be resent on next send_datagram)
            it = _arp_requests.erase(it);
        } else {
            // Decrement remaining time
            it->second -= ms_since_last_tick;
            ++it;
        }
    }
}
