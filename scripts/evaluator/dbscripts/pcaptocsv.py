#!/usr/bin/env python3
"""
Function to extract all relevant information from PCAPs to a CSV-based output
"""

import argparse
import binascii
import cProfile
import logging
import sys

from pypacker import ppcap

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def remove_checksums(buf):
    """
    Removing checksums as this is not meaningfull when comparing the results
    :param buf: The buffer
    :return:
    """
    ipv4 = 0
    ipv6 = 0
    other = 0

    ipv4_no_header = 0
    tcp = 0
    udp = 0
    icmp = 0
    other_l4 = 0

    if buf[12:14] == b'\x08\x00':
        ipv4 = 1

        if buf[14:15] != b'\x45':
            ipv4_no_header = 1
            return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4

        protocol = buf[23:24]
        if protocol == b'\x06': # TCP
            tcp = 1
            buf =  buf[:24] + b"\0\0" + buf[26:50] + b"\0\0" + buf[52:]
            return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4

        if protocol == b'\x11':  # UDP
            udp = 1
            buf = buf[:24] + b"\0\0" + buf[26:40] + b"\0\0" + buf[42:]
            return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4

        if protocol == b'\x01':  # ICMP
            icmp = 1
        else:  # other l4 proto
            other_l4 = 1
            logging.debug("Detected unknown IPv4 payload with protocol number: %s", protocol)

    elif buf[12:14] == b'\x86\xdd':
        ipv6 = 1
    else:
        other = 1

    return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4


def main():
    """
    Is the main function to calculate information and output the corresponding results
    :return:
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("pcap")
    parser.add_argument("--profile")

    args = parser.parse_args()

    pcap = ppcap.Reader(args.pcap)

    stats = dict(stats_ipv4=0, stats_ipv6=0, stats_other=0, stats_ipv4_no_header=0, stats_tcp=0,
                 stats_udp=0, stats_icmp=0, stats_other_l4=0)

    if args.profile:
        stats["profile"] = cProfile.Profile()
        stats["profile"].enable()

    try:
        for timestamp, buf in pcap:
            xbuf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4 = remove_checksums(buf[:64])

            stats["stats_ipv4"] += ipv4
            stats["stats_ipv6"] += ipv6
            stats["stats_other"] += other
            stats["stats_ipv4_no_header"] += ipv4_no_header
            stats["stats_tcp"] += tcp
            stats["stats_udp"] += udp
            stats["stats_icmp"] += icmp
            stats["stats_other_l4"] += other_l4

            try:
                # remove mac, since they cannot match in the VM setup
                sys.stdout.buffer.write(b"%d\t\\\\x%s\n" % (timestamp, binascii.b2a_hex(xbuf[12:])))
            except BrokenPipeError:
                logging.info("Broken Pipe (reader died?), exiting")
                break
    # suppress error when executing in python 3.7
    # changed behavior of StopIteration
    except RuntimeError:
        pass

    if stats.get("profile", None):
        stats["profile"].disable()
        stats["profile"].dump_stats(args.profile)

    logging.info("IPv4: %i [!options: %i] (TCP: %i, UDP: %i, ICMP: %i, other: %i), IPv6: %i, other: %i",
                 stats["stats_ipv4"], stats["stats_ipv4_no_header"], stats["stats_tcp"], stats["stats_udp"],
                 stats["stats_icmp"], stats["stats_other_l4"], stats["stats_ipv6"], stats["stats_other"])


if __name__ == "__main__":
    main()
