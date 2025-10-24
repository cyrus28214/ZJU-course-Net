#include "router.hh"

#include <iostream>

using namespace std;

//! \param[in] route_prefix The "up-to-32-bit" IPv4 address prefix to match the datagram's destination address against
//! \param[in] prefix_length For this route to be applicable, how many high-order (most-significant) bits of the route_prefix will need to match the corresponding bits of the datagram's destination address?
//! \param[in] next_hop The IP address of the next hop. Will be empty if the network is directly attached to the router (in which case, the next hop address should be the datagram's final destination).
//! \param[in] interface_num The index of the interface to send the datagram out on.
void Router::add_route(const uint32_t route_prefix,
                       const uint8_t prefix_length,
                       const optional<Address> next_hop,
                       const size_t interface_num) {
    cerr << "DEBUG: adding route " << Address::from_ipv4_numeric(route_prefix).ip() << "/" << int(prefix_length)
         << " => " << (next_hop.has_value() ? next_hop->ip() : "(direct)") << " on interface " << interface_num << "\n";

    // Add the route entry to the routing table
    _routing_table.push_back({route_prefix, prefix_length, next_hop, interface_num});
}

//! \param[in] dgram The datagram to be routed
void Router::route_one_datagram(InternetDatagram &dgram) {
    // Check if TTL is valid (must be > 1 to forward after decrement)
    if (dgram.header().ttl <= 1) {
        return;  // Discard the datagram (TTL expired or will expire)
    }

    // Decrement TTL
    dgram.header().ttl--;

    // Find the longest prefix match in the routing table
    const uint32_t dst_ip = dgram.header().dst;
    int best_match_idx = -1;
    uint8_t longest_prefix = 0;

    for (size_t i = 0; i < _routing_table.size(); i++) {
        const auto &route = _routing_table[i];
        const uint8_t prefix_len = route.prefix_length;

        // Create a mask for the prefix
        uint32_t mask = 0;
        if (prefix_len > 0) {
            if (prefix_len == 32) {
                mask = 0xFFFFFFFF;
            } else {
                mask = ~((1U << (32 - prefix_len)) - 1);
            }
        }

        // Check if the destination IP matches this route's prefix
        if ((dst_ip & mask) == (route.route_prefix & mask)) {
            // This route matches; check if it's the longest prefix so far
            if (prefix_len >= longest_prefix) {
                longest_prefix = prefix_len;
                best_match_idx = i;
            }
        }
    }

    // If no matching route found, discard the datagram
    if (best_match_idx == -1) {
        return;
    }

    // Get the best matching route
    const auto &best_route = _routing_table[best_match_idx];

    // Determine the next hop address
    Address next_hop_addr = best_route.next_hop.value_or(Address::from_ipv4_numeric(dst_ip));

    // Send the datagram out on the appropriate interface
    _interfaces[best_route.interface_num].send_datagram(dgram, next_hop_addr);
}

void Router::route() {
    // Go through all the interfaces, and route every incoming datagram to its proper outgoing interface.
    for (auto &interface : _interfaces) {
        auto &queue = interface.datagrams_out();
        while (not queue.empty()) {
            route_one_datagram(queue.front());
            queue.pop();
        }
    }
}
