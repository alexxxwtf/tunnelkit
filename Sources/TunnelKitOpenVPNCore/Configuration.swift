//
//  Configuration.swift
//  TunnelKit
//
//  Created by Davide De Rosa on 8/23/18.
//  Copyright (c) 2023 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of TunnelKit.
//
//  TunnelKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  TunnelKit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with TunnelKit.  If not, see <http://www.gnu.org/licenses/>.
//
//  This file incorporates work covered by the following copyright and
//  permission notice:
//
//      Copyright (c) 2018-Present Private Internet Access
//
//      Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//      The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import SwiftyBeaver
import TunnelKitCore

private let log = SwiftyBeaver.self

extension OpenVPN {

    /// A pair of credentials for authentication.
    public struct Credentials: Codable, Equatable {

        /// The username.
        public let username: String

        /// The password.
        public let password: String

        public init(_ username: String, _ password: String) {
            self.username = username
            self.password = password
        }
    }

    /// Encryption algorithm.
    public enum Cipher: String, Codable, CustomStringConvertible {

        // WARNING: must match OpenSSL algorithm names

        /// AES encryption with 128-bit key size and CBC.
        case aes128cbc = "AES-128-CBC"

        /// AES encryption with 192-bit key size and CBC.
        case aes192cbc = "AES-192-CBC"

        /// AES encryption with 256-bit key size and CBC.
        case aes256cbc = "AES-256-CBC"

        /// AES encryption with 128-bit key size and GCM.
        case aes128gcm = "AES-128-GCM"

        /// AES encryption with 192-bit key size and GCM.
        case aes192gcm = "AES-192-GCM"

        /// AES encryption with 256-bit key size and GCM.
        case aes256gcm = "AES-256-GCM"

        /// Returns the key size for this cipher.
        public var keySize: Int {
            switch self {
            case .aes128cbc, .aes128gcm:
                return 128

            case .aes192cbc, .aes192gcm:
                return 192

            case .aes256cbc, .aes256gcm:
                return 256
            }
        }

        /// Digest should be ignored when this is `true`.
        public var embedsDigest: Bool {
            return rawValue.hasSuffix("-GCM")
        }

        /// Returns a generic name for this cipher.
        public var genericName: String {
            return rawValue.hasSuffix("-GCM") ? "AES-GCM" : "AES-CBC"
        }

        public var description: String {
            return rawValue
        }
    }

    /// Message digest algorithm.
    public enum Digest: String, Codable, CustomStringConvertible {

        // WARNING: must match OpenSSL algorithm names

        /// SHA1 message digest.
        case sha1 = "SHA1"

        /// SHA224 message digest.
        case sha224 = "SHA224"

        /// SHA256 message digest.
        case sha256 = "SHA256"

        /// SHA256 message digest.
        case sha384 = "SHA384"

        /// SHA256 message digest.
        case sha512 = "SHA512"

        /// Returns a generic name for this digest.
        public var genericName: String {
            return "HMAC"
        }

        public var description: String {
            return "\(genericName)-\(rawValue)"
        }
    }

    /// Routing policy.
    public enum RoutingPolicy: String, Codable {

        /// All IPv4 traffic goes through the VPN.
        case IPv4

        /// All IPv6 traffic goes through the VPN.
        case IPv6

        /// Block LAN while connected.
        case blockLocal
    }

    /// Settings that can be pulled from server.
    public enum PullMask: String, Codable, CaseIterable {

        /// Routes and gateways.
        case routes

        /// DNS settings.
        case dns

        /// Proxy settings.
        case proxy
    }

    /// The way to create a `Configuration` object for a `OpenVPNSession`.
    public struct ConfigurationBuilder {

        // MARK: General

        /// The cipher algorithm for data encryption.
        public var cipher: Cipher?

        /// The set of supported cipher algorithms for data encryption (2.5.).
        public var dataCiphers: [Cipher]?

        /// The digest algorithm for HMAC.
        public var digest: Digest?

        /// Compression framing, disabled by default.
        public var compressionFraming: CompressionFraming?

        /// Compression algorithm, disabled by default.
        public var compressionAlgorithm: CompressionAlgorithm?

        /// The CA for TLS negotiation (PEM format).
        public var ca: CryptoContainer?

        /// The optional client certificate for TLS negotiation (PEM format).
        public var clientCertificate: CryptoContainer?

        /// The private key for the certificate in `clientCertificate` (PEM format).
        public var clientKey: CryptoContainer?

        /// The optional TLS wrapping.
        public var tlsWrap: TLSWrap?

        /// If set, overrides TLS security level (0 = lowest).
        public var tlsSecurityLevel: Int?

        /// Sends periodical keep-alive packets if set.
        public var keepAliveInterval: TimeInterval?

        /// Disconnects after no keep-alive packets are received within timeout interval if set.
        public var keepAliveTimeout: TimeInterval?

        /// The number of seconds after which a renegotiation should be initiated. If `nil`, the client will never initiate a renegotiation.
        public var renegotiatesAfter: TimeInterval?

        // MARK: Client

        /// The list of server endpoints.
        public var remotes: [Endpoint]?

        /// If true, checks EKU of server certificate.
        public var checksEKU: Bool?

        /// If true, checks if hostname (sanHost) is present in certificates SAN.
        public var checksSANHost: Bool?

        /// The server hostname used for checking certificate SAN.
        public var sanHost: String?

        /// Picks endpoint from `remotes` randomly.
        public var randomizeEndpoint: Bool?

        /// Prepend hostnames with a number of random bytes defined in `Configuration.randomHostnamePrefixLength`.
        public var randomizeHostnames: Bool?

        /// Server is patched for the PIA VPN provider.
        public var usesPIAPatches: Bool?

        /// The tunnel MTU.
        public var mtu: Int?

        /// Requires username authentication.
        public var authUserPass: Bool?

        // MARK: Server

        /// The auth-token returned by the server.
        public var authToken: String?

        /// The peer-id returned by the server.
        public var peerId: UInt32?

        // MARK: Routing

        /// The settings for IPv4. `OpenVPNSession` only evaluates this server-side.
        public var ipv4: IPv4Settings?

        /// The settings for IPv6. `OpenVPNSession` only evaluates this server-side.
        public var ipv6: IPv6Settings?

        /// The IPv4 routes if `ipv4` is nil.
        public var routes4: [IPv4Settings.Route]?

        /// The IPv6 routes if `ipv6` is nil.
        public var routes6: [IPv6Settings.Route]?

        /// Set false to ignore DNS settings, even when pushed.
        public var isDNSEnabled: Bool?

        /// The DNS protocol, defaults to `.plain` (iOS 14+ / macOS 11+).
        public var dnsProtocol: DNSProtocol?

        /// The DNS servers if `dnsProtocol = .plain` or nil.
        public var dnsServers: [String]?

        /// The server URL if `dnsProtocol = .https`.
        public var dnsHTTPSURL: URL?

        /// The server name if `dnsProtocol = .tls`.
        public var dnsTLSServerName: String?

        /// The main domain name.
        public var dnsDomain: String?

        /// The search domain.
        @available(*, deprecated, message: "Use searchDomains instead")
        public var searchDomain: String? {
            didSet {
                guard let searchDomain = searchDomain else {
                    searchDomains = nil
                    return
                }
                searchDomains = [searchDomain]
            }
        }

        /// The search domains.
        public var searchDomains: [String]?

        /// The Proxy Auto-Configuration (PAC) url.
        public var proxyAutoConfigurationURL: URL?

        /// Set false to ignore proxy settings, even when pushed.
        public var isProxyEnabled: Bool?

        /// The HTTP proxy.
        public var httpProxy: Proxy?

        /// The HTTPS proxy.
        public var httpsProxy: Proxy?

        /// The list of domains not passing through the proxy.
        public var proxyBypassDomains: [String]?

        /// Policies for redirecting traffic through the VPN gateway.
        public var routingPolicies: [RoutingPolicy]?

        /// Server settings that must not be pulled.
        public var noPullMask: [PullMask]?

        // MARK: Extra

        /// The method to follow in regards to the XOR patch.
        public var xorMethod: XORMethod?

        /**
         Creates a `ConfigurationBuilder`.
         
         - Parameter withFallbacks: If `true`, initializes builder with fallback values rather than nil.
         */
        public init(withFallbacks: Bool = false) {
            if withFallbacks {
                cipher = Configuration.Fallback.cipher
                digest = Configuration.Fallback.digest
                compressionFraming = Configuration.Fallback.compressionFraming
                compressionAlgorithm = Configuration.Fallback.compressionAlgorithm
            }
        }

        /**
         Builds a `Configuration` object.
         
         - Returns: A `Configuration` object with this builder.
         */
        public func build() -> Configuration {
            return Configuration(
                cipher: cipher,
                dataCiphers: dataCiphers,
                digest: digest,
                compressionFraming: compressionFraming,
                compressionAlgorithm: compressionAlgorithm,
                ca: ca,
                clientCertificate: clientCertificate,
                clientKey: clientKey,
                tlsWrap: tlsWrap,
                tlsSecurityLevel: tlsSecurityLevel,
                keepAliveInterval: keepAliveInterval,
                keepAliveTimeout: keepAliveTimeout,
                renegotiatesAfter: renegotiatesAfter,
                remotes: remotes,
                checksEKU: checksEKU,
                checksSANHost: checksSANHost,
                sanHost: sanHost,
                randomizeEndpoint: randomizeEndpoint,
                randomizeHostnames: randomizeHostnames,
                usesPIAPatches: usesPIAPatches,
                mtu: mtu,
                authUserPass: authUserPass,
                authToken: authToken,
                peerId: peerId,
                ipv4: ipv4,
                ipv6: ipv6,
                routes4: routes4,
                routes6: routes6,
                isDNSEnabled: isDNSEnabled,
                dnsProtocol: dnsProtocol,
                dnsServers: dnsServers,
                dnsHTTPSURL: dnsHTTPSURL,
                dnsTLSServerName: dnsTLSServerName,
                dnsDomain: dnsDomain,
                searchDomains: searchDomains,
                isProxyEnabled: isProxyEnabled,
                httpProxy: httpProxy,
                httpsProxy: httpsProxy,
                proxyAutoConfigurationURL: proxyAutoConfigurationURL,
                proxyBypassDomains: proxyBypassDomains,
                routingPolicies: routingPolicies,
                noPullMask: noPullMask,
                xorMethod: xorMethod
            )
        }
    }

    /// The immutable configuration for `OpenVPNSession`.
    public struct Configuration: Codable, Equatable {
        struct Fallback {
            static let cipher: Cipher = .aes128cbc

            static let digest: Digest = .sha1

            static let compressionFraming: CompressionFraming = .disabled

            static let compressionAlgorithm: CompressionAlgorithm = .disabled
        }

        private static let randomHostnamePrefixLength = 6

        /// - Seealso: `ConfigurationBuilder.cipher`
        public let cipher: Cipher?

        /// - Seealso: `ConfigurationBuilder.dataCiphers`
        public let dataCiphers: [Cipher]?

        /// - Seealso: `ConfigurationBuilder.digest`
        public let digest: Digest?

        /// - Seealso: `ConfigurationBuilder.compressionFraming`
        public let compressionFraming: CompressionFraming?

        /// - Seealso: `ConfigurationBuilder.compressionAlgorithm`
        public let compressionAlgorithm: CompressionAlgorithm?

        /// - Seealso: `ConfigurationBuilder.ca`
        public let ca: CryptoContainer?

        /// - Seealso: `ConfigurationBuilder.clientCertificate`
        public let clientCertificate: CryptoContainer?

        /// - Seealso: `ConfigurationBuilder.clientKey`
        public let clientKey: CryptoContainer?

        /// - Seealso: `ConfigurationBuilder.tlsWrap`
        public let tlsWrap: TLSWrap?

        /// - Seealso: `ConfigurationBuilder.tlsSecurityLevel`
        public let tlsSecurityLevel: Int?

        /// - Seealso: `ConfigurationBuilder.keepAliveInterval`
        public let keepAliveInterval: TimeInterval?

        /// - Seealso: `ConfigurationBuilder.keepAliveTimeout`
        public let keepAliveTimeout: TimeInterval?

        /// - Seealso: `ConfigurationBuilder.renegotiatesAfter`
        public let renegotiatesAfter: TimeInterval?

        /// - Seealso: `ConfigurationBuilder.remotes`
        public let remotes: [Endpoint]?

        /// - Seealso: `ConfigurationBuilder.checksEKU`
        public let checksEKU: Bool?

        /// - Seealso: `ConfigurationBuilder.checksSANHost`
        public let checksSANHost: Bool?

        /// - Seealso: `ConfigurationBuilder.sanHost`
        public let sanHost: String?

        /// - Seealso: `ConfigurationBuilder.randomizeEndpoint`
        public let randomizeEndpoint: Bool?

        /// - Seealso: `ConfigurationBuilder.randomizeHostnames`
        public var randomizeHostnames: Bool?

        /// - Seealso: `ConfigurationBuilder.usesPIAPatches`
        public let usesPIAPatches: Bool?

        /// - Seealso: `ConfigurationBuilder.mtu`
        public let mtu: Int?

        /// - Seealso: `ConfigurationBuilder.authUserPass`
        public let authUserPass: Bool?

        /// - Seealso: `ConfigurationBuilder.authToken`
        public let authToken: String?

        /// - Seealso: `ConfigurationBuilder.peerId`
        public let peerId: UInt32?

        /// - Seealso: `ConfigurationBuilder.ipv4`
        public let ipv4: IPv4Settings?

        /// - Seealso: `ConfigurationBuilder.ipv6`
        public let ipv6: IPv6Settings?

        /// - Seealso: `ConfigurationBuilder.routes4`
        public let routes4: [IPv4Settings.Route]?

        /// - Seealso: `ConfigurationBuilder.routes6`
        public let routes6: [IPv6Settings.Route]?

        /// - Seealso: `ConfigurationBuilder.isDNSEnabled`
        public let isDNSEnabled: Bool?

        /// - Seealso: `ConfigurationBuilder.dnsProtocol`
        public let dnsProtocol: DNSProtocol?

        /// - Seealso: `ConfigurationBuilder.dnsServers`
        public let dnsServers: [String]?

        /// - Seealso: `ConfigurationBuilder.dnsHTTPSURL`
        public let dnsHTTPSURL: URL?

        /// - Seealso: `ConfigurationBuilder.dnsTLSServerName`
        public let dnsTLSServerName: String?

        /// - Seealso: `ConfigurationBuilder.dnsDomain`
        public let dnsDomain: String?

        /// - Seealso: `ConfigurationBuilder.searchDomains`
        public let searchDomains: [String]?

        /// - Seealso: `ConfigurationBuilder.isProxyEnabled`
        public let isProxyEnabled: Bool?

        /// - Seealso: `ConfigurationBuilder.httpProxy`
        public let httpProxy: Proxy?

        /// - Seealso: `ConfigurationBuilder.httpsProxy`
        public let httpsProxy: Proxy?

        /// - Seealso: `ConfigurationBuilder.proxyAutoConfigurationURL`
        public let proxyAutoConfigurationURL: URL?

        /// - Seealso: `ConfigurationBuilder.proxyBypassDomains`
        public let proxyBypassDomains: [String]?

        /// - Seealso: `ConfigurationBuilder.routingPolicies`
        public let routingPolicies: [RoutingPolicy]?

        /// - Seealso: `ConfigurationBuilder.noPullMask`
        public let noPullMask: [PullMask]?

        /// - Seealso: `ConfigurationBuilder.xorMethod`
        public let xorMethod: XORMethod?

        // MARK: Shortcuts

        public var fallbackCipher: Cipher {
            return cipher ?? Fallback.cipher
        }

        public var fallbackDigest: Digest {
            return digest ?? Fallback.digest
        }

        public var fallbackCompressionFraming: CompressionFraming {
            return compressionFraming ?? Fallback.compressionFraming
        }

        public var fallbackCompressionAlgorithm: CompressionAlgorithm {
            return compressionAlgorithm ?? Fallback.compressionAlgorithm
        }

        public var pullMask: [PullMask]? {
            let all = PullMask.allCases
            guard let notPulled = noPullMask else {
                return all
            }
            let pulled = Array(Set(all).subtracting(notPulled))
            return !pulled.isEmpty ? pulled : nil
        }

        // MARK: Computed

        public var processedRemotes: [Endpoint]? {
            guard var processedRemotes = remotes else {
                return nil
            }
            if randomizeEndpoint ?? false {
                processedRemotes.shuffle()
            }
            if let randomPrefixLength = (randomizeHostnames ?? false) ? Self.randomHostnamePrefixLength : nil {
                processedRemotes = processedRemotes.compactMap {
                    do {
                        return try $0.withRandomPrefixLength(randomPrefixLength)
                    } catch {
                        log.warning("Could not prepend random prefix: \(error)")
                        return nil
                    }
                }
            }
            return processedRemotes
        }
    }
}

// MARK: Modification

extension OpenVPN.Configuration {

    /**
     Returns a `ConfigurationBuilder` to use this configuration as a starting point for a new one.
     
     - Parameter withFallbacks: If `true`, initializes builder with fallback values rather than nil.
     - Returns: An editable `ConfigurationBuilder` initialized with this configuration.
     */
    public func builder(withFallbacks: Bool = false) -> OpenVPN.ConfigurationBuilder {
        var builder = OpenVPN.ConfigurationBuilder()
        builder.cipher = cipher ?? (withFallbacks ? Fallback.cipher : nil)
        builder.dataCiphers = dataCiphers
        builder.digest = digest ?? (withFallbacks ? Fallback.digest : nil)
        builder.compressionFraming = compressionFraming ?? (withFallbacks ? Fallback.compressionFraming : nil)
        builder.compressionAlgorithm = compressionAlgorithm ?? (withFallbacks ? Fallback.compressionAlgorithm : nil)
        builder.ca = ca
        builder.clientCertificate = clientCertificate
        builder.clientKey = clientKey
        builder.tlsWrap = tlsWrap
        builder.tlsSecurityLevel = tlsSecurityLevel
        builder.keepAliveInterval = keepAliveInterval
        builder.keepAliveTimeout = keepAliveTimeout
        builder.renegotiatesAfter = renegotiatesAfter
        builder.remotes = remotes
        builder.checksEKU = checksEKU
        builder.checksSANHost = checksSANHost
        builder.sanHost = sanHost
        builder.randomizeEndpoint = randomizeEndpoint
        builder.randomizeHostnames = randomizeHostnames
        builder.usesPIAPatches = usesPIAPatches
        builder.mtu = mtu
        builder.authUserPass = authUserPass
        builder.authToken = authToken
        builder.peerId = peerId
        builder.ipv4 = ipv4
        builder.ipv6 = ipv6
        builder.routes4 = routes4
        builder.routes6 = routes6
        builder.isDNSEnabled = isDNSEnabled
        builder.dnsProtocol = dnsProtocol
        builder.dnsServers = dnsServers
        builder.dnsHTTPSURL = dnsHTTPSURL
        builder.dnsTLSServerName = dnsTLSServerName
        builder.dnsDomain = dnsDomain
        builder.searchDomains = searchDomains
        builder.isProxyEnabled = isProxyEnabled
        builder.httpProxy = httpProxy
        builder.httpsProxy = httpsProxy
        builder.proxyAutoConfigurationURL = proxyAutoConfigurationURL
        builder.proxyBypassDomains = proxyBypassDomains
        builder.routingPolicies = routingPolicies
        builder.noPullMask = noPullMask
        builder.xorMethod = xorMethod
        return builder
    }
}

// MARK: Encoding

extension OpenVPN.Configuration {
    public func print(isLocal: Bool) {
        if isLocal {
            guard let remotes = remotes else {
                fatalError("No remotes set")
            }
            log.info("\tRemotes: \(remotes)")
        }

        if !isLocal {
            log.info("\tIPv4: \(ipv4?.description ?? "not configured")")
            log.info("\tIPv6: \(ipv6?.description ?? "not configured")")
        }
        if let routes = routes4 {
            log.info("\tRoutes (IPv4): \(routes)")
        }
        if let routes = routes6 {
            log.info("\tRoutes (IPv6): \(routes)")
        }

        if let cipher = cipher {
            log.info("\tCipher: \(cipher)")
        } else if isLocal {
            log.info("\tCipher: \(fallbackCipher)")
        }
        if let digest = digest {
            log.info("\tDigest: \(digest)")
        } else if isLocal {
            log.info("\tDigest: \(fallbackDigest)")
        }
        if let compressionFraming = compressionFraming {
            log.info("\tCompression framing: \(compressionFraming)")
        } else if isLocal {
            log.info("\tCompression framing: \(fallbackCompressionFraming)")
        }
        if let compressionAlgorithm = compressionAlgorithm {
            log.info("\tCompression algorithm: \(compressionAlgorithm)")
        } else if isLocal {
            log.info("\tCompression algorithm: \(fallbackCompressionAlgorithm)")
        }

        if isLocal {
            log.info("\tUsername authentication: \(authUserPass ?? false)")
            if let _ = clientCertificate {
                log.info("\tClient verification: enabled")
            } else {
                log.info("\tClient verification: disabled")
            }
            if let tlsWrap = tlsWrap {
                log.info("\tTLS wrapping: \(tlsWrap.strategy)")
            } else {
                log.info("\tTLS wrapping: disabled")
            }
            if let tlsSecurityLevel = tlsSecurityLevel {
                log.info("\tTLS security level: \(tlsSecurityLevel)")
            } else {
                log.info("\tTLS security level: default")
            }
        }

        if let keepAliveSeconds = keepAliveInterval, keepAliveSeconds > 0 {
            log.info("\tKeep-alive interval: \(keepAliveSeconds.asTimeString)")
        } else if isLocal {
            log.info("\tKeep-alive interval: never")
        }
        if let keepAliveTimeoutSeconds = keepAliveTimeout, keepAliveTimeoutSeconds > 0 {
            log.info("\tKeep-alive timeout: \(keepAliveTimeoutSeconds.asTimeString)")
        } else if isLocal {
            log.info("\tKeep-alive timeout: never")
        }
        if let renegotiatesAfterSeconds = renegotiatesAfter, renegotiatesAfterSeconds > 0 {
            log.info("\tRenegotiation: \(renegotiatesAfterSeconds.asTimeString)")
        } else if isLocal {
            log.info("\tRenegotiation: never")
        }
        if checksEKU ?? false {
            log.info("\tServer EKU verification: enabled")
        } else if isLocal {
            log.info("\tServer EKU verification: disabled")
        }
        if checksSANHost ?? false {
            log.info("\tHost SAN verification: enabled (\(sanHost ?? "-"))")
        } else if isLocal {
            log.info("\tHost SAN verification: disabled")
        }

        if randomizeEndpoint ?? false {
            log.info("\tRandomize endpoint: true")
        }
        if randomizeHostnames ?? false {
            log.info("\tRandomize hostnames: true")
        }

        if let routingPolicies = routingPolicies {
            log.info("\tGateway: \(routingPolicies.map(\.rawValue))")
        } else if isLocal {
            log.info("\tGateway: not configured")
        }

        switch dnsProtocol {
        case .https:
            if let dnsHTTPSURL = dnsHTTPSURL {
                log.info("\tDNS over HTTPS: \(dnsHTTPSURL.maskedDescription)")
            } else if isLocal {
                log.info("\tDNS: not configured")
            }

        case .tls:
            if let dnsTLSServerName = dnsTLSServerName {
                log.info("\tDNS over TLS: \(dnsTLSServerName.maskedDescription)")
            } else if isLocal {
                log.info("\tDNS: not configured")
            }

        default:
            if let dnsServers = dnsServers, !dnsServers.isEmpty {
                log.info("\tDNS: \(dnsServers.maskedDescription)")
            } else if isLocal {
                log.info("\tDNS: not configured")
            }
        }
        if let dnsDomain = dnsDomain, !dnsDomain.isEmpty {
            log.info("\tDNS domain: \(dnsDomain.maskedDescription)")
        }
        if let searchDomains = searchDomains, !searchDomains.isEmpty {
            log.info("\tSearch domains: \(searchDomains.maskedDescription)")
        }

        if let httpProxy = httpProxy {
            log.info("\tHTTP proxy: \(httpProxy.maskedDescription)")
        }
        if let httpsProxy = httpsProxy {
            log.info("\tHTTPS proxy: \(httpsProxy.maskedDescription)")
        }
        if let proxyAutoConfigurationURL = proxyAutoConfigurationURL {
            log.info("\tPAC: \(proxyAutoConfigurationURL)")
        }
        if let proxyBypassDomains = proxyBypassDomains {
            log.info("\tProxy bypass domains: \(proxyBypassDomains.maskedDescription)")
        }

        if let mtu = mtu {
            log.info("\tMTU: \(mtu)")
        } else if isLocal {
            log.info("\tMTU: default")
        }

        if isLocal, let noPullMask = noPullMask {
            log.info("\tNot pulled: \(noPullMask.map(\.rawValue))")
        }
    }
}
