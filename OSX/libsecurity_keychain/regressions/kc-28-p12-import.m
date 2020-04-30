/*
 * Copyright (c) 2016 Apple Inc. All Rights Reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the xLicense.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

#import <Security/Security.h>
#include "keychain_regressions.h"
#include "kc-helpers.h"
#include "kc-item-helpers.h"
#include "kc-key-helpers.h"
#include "kc-identity-helpers.h"

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Security/oidscert.h>
#include <Security/oidsattr.h>
#include <Security/oidsalg.h>
#include <Security/x509defs.h>
#include <Security/cssmapi.h>
#include <Security/cssmapple.h>
#include <Security/certextensions.h>

#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>
#include <Security/SecImportExport.h>
#include <Security/SecIdentity.h>
#include <Security/SecIdentitySearch.h>
#include <Security/SecKey.h>
#include <Security/SecCertificate.h>
#include <Security/SecItem.h>

// Turn off deprecated API warnings
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"


unsigned char test_import_p12[] = {
    0x30, 0x82, 0x09, 0xbf, 0x02, 0x01, 0x03, 0x30, 0x82, 0x09, 0x86, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01,
    0x07, 0x01, 0xa0, 0x82, 0x09, 0x77, 0x04, 0x82, 0x09, 0x73, 0x30, 0x82, 0x09, 0x6f, 0x30, 0x82, 0x03, 0xff, 0x06, 0x09,
    0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x06, 0xa0, 0x82, 0x03, 0xf0, 0x30, 0x82, 0x03, 0xec, 0x02, 0x01, 0x00,
    0x30, 0x82, 0x03, 0xe5, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x01, 0x30, 0x1c, 0x06, 0x0a, 0x2a,
    0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x0c, 0x01, 0x06, 0x30, 0x0e, 0x04, 0x08, 0xcb, 0xa2, 0x8c, 0x60, 0xc2, 0x36, 0x55,
    0x05, 0x02, 0x02, 0x08, 0x00, 0x80, 0x82, 0x03, 0xb8, 0x57, 0x1d, 0x4c, 0x1f, 0xc7, 0x4c, 0x00, 0x82, 0xa3, 0xc9, 0x6f,
    0x2e, 0x00, 0x03, 0x1b, 0x55, 0xaa, 0xe5, 0x89, 0x58, 0x18, 0x71, 0xb8, 0xff, 0x40, 0x13, 0xd5, 0xac, 0x7f, 0xf1, 0x48,
    0xb2, 0x7e, 0x6e, 0xeb, 0x6e, 0xde, 0xe8, 0x35, 0x22, 0xa5, 0x45, 0x5a, 0xa6, 0x2e, 0xed, 0x0d, 0xe0, 0x8f, 0x2f, 0x60,
    0x5c, 0xd8, 0x49, 0x89, 0x26, 0x42, 0xd6, 0xe0, 0x24, 0x1c, 0x59, 0x9c, 0xe0, 0xbf, 0x98, 0x0c, 0xc3, 0x81, 0x20, 0x47,
    0x03, 0x03, 0xe2, 0x73, 0x90, 0x13, 0x6e, 0x96, 0x31, 0x68, 0xb7, 0x8f, 0xaa, 0x25, 0x4b, 0x27, 0x95, 0x3f, 0xef, 0xa3,
    0x2b, 0x96, 0x10, 0x85, 0xf3, 0x49, 0x3c, 0x6f, 0x9a, 0x20, 0x02, 0x17, 0x42, 0xe9, 0x9c, 0x5e, 0x5d, 0x4b, 0x3c, 0x88,
    0x65, 0xf5, 0x67, 0x61, 0x3e, 0xa6, 0x1a, 0x0f, 0x5b, 0x1e, 0x35, 0x18, 0x4e, 0xf3, 0x98, 0x93, 0x7e, 0x76, 0x77, 0x31,
    0x3b, 0x00, 0x78, 0x8c, 0x50, 0x28, 0x76, 0xca, 0xc8, 0x39, 0xc5, 0xf5, 0x79, 0x23, 0x4a, 0xea, 0x9a, 0xf0, 0xb5, 0xb6,
    0x50, 0x8d, 0x16, 0xd9, 0x39, 0x74, 0x36, 0x1d, 0x26, 0xcb, 0xbf, 0xb7, 0x72, 0x5e, 0x77, 0xf5, 0xb8, 0x35, 0xfc, 0x66,
    0x4d, 0xdc, 0xd6, 0x20, 0x50, 0x70, 0xc6, 0xf7, 0x13, 0x55, 0xb1, 0x97, 0x7e, 0x1d, 0x6a, 0x7d, 0x73, 0xc2, 0x71, 0x49,
    0xd1, 0x15, 0xe7, 0x30, 0xa7, 0x52, 0x1f, 0x24, 0xe8, 0x7b, 0xd7, 0x81, 0x53, 0x27, 0x94, 0xd0, 0x31, 0xe5, 0x11, 0xe4,
    0x90, 0x8a, 0x02, 0x46, 0x70, 0x82, 0xe7, 0xc4, 0xfe, 0xb5, 0xed, 0xb0, 0x1b, 0xcb, 0xa2, 0x23, 0x5c, 0xd2, 0x95, 0xe6,
    0x2c, 0x5f, 0x2d, 0x07, 0xb1, 0xd8, 0xe8, 0xa0, 0x39, 0xe7, 0xdd, 0x2e, 0x36, 0xac, 0x38, 0xfc, 0x65, 0x99, 0x2c, 0xda,
    0x3d, 0x26, 0x5d, 0x1e, 0x2f, 0xbc, 0x31, 0x36, 0x3e, 0x87, 0x55, 0x5f, 0x40, 0xf1, 0x77, 0x7a, 0x15, 0xa2, 0xc3, 0xe4,
    0x21, 0xc0, 0xe1, 0x11, 0x15, 0x31, 0xf4, 0x7a, 0x51, 0xc3, 0x78, 0x70, 0xfc, 0x3b, 0xed, 0x04, 0x7f, 0x5c, 0xaf, 0x22,
    0x37, 0x1c, 0x80, 0xb6, 0x7b, 0xdf, 0x11, 0x90, 0x52, 0xc1, 0x0d, 0xfb, 0xaa, 0xd0, 0x43, 0x47, 0xe9, 0xdb, 0x31, 0xb7,
    0xfc, 0x35, 0xbf, 0xce, 0x00, 0x15, 0x0d, 0x51, 0xb1, 0x78, 0x99, 0x55, 0x91, 0x1f, 0xf1, 0x4c, 0x36, 0xfa, 0xc1, 0xa0,
    0xce, 0x86, 0xc9, 0x79, 0x60, 0x07, 0x58, 0xa7, 0xe5, 0x28, 0x28, 0x84, 0x92, 0x03, 0x2c, 0x43, 0xda, 0x69, 0xce, 0x75,
    0x25, 0x01, 0x51, 0x37, 0xd4, 0xfd, 0xa2, 0xc4, 0x09, 0xfb, 0xa0, 0xf5, 0x1f, 0x23, 0x7b, 0xd6, 0x63, 0xd1, 0xb5, 0x5b,
    0xc5, 0xd9, 0xbc, 0xe7, 0xd4, 0x5e, 0x8b, 0x62, 0xee, 0xdb, 0xb7, 0x1e, 0xd2, 0x8b, 0x6e, 0xe4, 0x8c, 0xfd, 0x11, 0x25,
    0xda, 0xac, 0x2a, 0x7a, 0x9a, 0xad, 0x6c, 0x29, 0xe1, 0x1c, 0x68, 0x4f, 0xb3, 0x99, 0x06, 0xb4, 0x72, 0x2a, 0x5a, 0x70,
    0xd6, 0xf6, 0x7c, 0x22, 0x0f, 0x85, 0xf1, 0xc4, 0x30, 0x9f, 0x32, 0x53, 0xa1, 0xb2, 0x1a, 0x41, 0x01, 0xa2, 0x92, 0x58,
    0xa2, 0x27, 0xe8, 0x09, 0xed, 0x75, 0x84, 0x41, 0xcd, 0x19, 0x46, 0x47, 0x86, 0x7d, 0xa0, 0x49, 0xc4, 0x72, 0x94, 0x9f,
    0x43, 0xf2, 0x09, 0x3a, 0x59, 0x56, 0x7c, 0x3b, 0x34, 0x79, 0x1b, 0x58, 0x82, 0xc7, 0x64, 0x19, 0x7c, 0x32, 0x7b, 0x42,
    0x66, 0x9f, 0x32, 0xef, 0x48, 0xb4, 0xf7, 0xd0, 0x74, 0x1f, 0x1c, 0xbe, 0xd4, 0x7a, 0x2a, 0x02, 0xb2, 0x3d, 0x47, 0x15,
    0x40, 0xa8, 0xd5, 0x57, 0xc8, 0xe7, 0x7d, 0x8d, 0xa6, 0xea, 0xe5, 0x21, 0x6a, 0xbe, 0x39, 0x8c, 0xfd, 0x78, 0x26, 0xaf,
    0x31, 0x93, 0x0f, 0x94, 0x07, 0x87, 0x6c, 0xa8, 0x56, 0xd8, 0xc6, 0x79, 0xcf, 0x1d, 0x36, 0xee, 0xab, 0x33, 0x5b, 0x63,
    0xe8, 0x34, 0x00, 0x0c, 0x95, 0x48, 0x34, 0xac, 0xe2, 0xda, 0x61, 0x7a, 0x97, 0x3e, 0x41, 0xe4, 0xb7, 0x30, 0xb0, 0xb3,
    0x96, 0xed, 0x91, 0xb8, 0x5b, 0x20, 0x30, 0xfa, 0xf0, 0xfa, 0xc7, 0xc2, 0x97, 0x14, 0x9b, 0x81, 0xa9, 0x70, 0x8a, 0x10,
    0xf1, 0x75, 0xe4, 0xec, 0x54, 0x3e, 0xd9, 0xa8, 0x94, 0xcd, 0x3a, 0x82, 0xf7, 0xe3, 0xb8, 0x75, 0xd7, 0x49, 0x6c, 0x80,
    0x97, 0xd8, 0xdf, 0x56, 0x66, 0x93, 0xe6, 0xef, 0xa3, 0xc3, 0xd6, 0x34, 0xb7, 0x6f, 0x9b, 0x51, 0xaa, 0x7c, 0x1e, 0x16,
    0x8f, 0x21, 0x8a, 0x0a, 0x9f, 0x0e, 0xbe, 0x6b, 0x96, 0x8b, 0x95, 0x95, 0x5d, 0x11, 0x39, 0x15, 0x8c, 0xca, 0x9d, 0xec,
    0x26, 0x39, 0x49, 0x1e, 0xf6, 0x16, 0x09, 0x36, 0x95, 0xae, 0xa0, 0x55, 0xbf, 0x94, 0xf2, 0x6f, 0x1b, 0x74, 0x93, 0x97,
    0x6d, 0xd8, 0x00, 0x0c, 0xf0, 0x9e, 0x24, 0xb9, 0xfe, 0x04, 0xfa, 0x30, 0x63, 0x90, 0x28, 0xcb, 0x0d, 0x8e, 0xe8, 0xf0,
    0x7f, 0x9a, 0x69, 0x54, 0xf2, 0xbc, 0x9f, 0x24, 0x0b, 0xd1, 0xda, 0x2f, 0x22, 0x81, 0x22, 0x31, 0x03, 0xc2, 0x60, 0x41,
    0x2e, 0xe0, 0xc6, 0x52, 0x7b, 0x5a, 0x35, 0xbc, 0x00, 0xfd, 0x71, 0x00, 0x19, 0xd3, 0xa4, 0xa8, 0x5b, 0xbc, 0xfc, 0xae,
    0x24, 0x10, 0xb4, 0x21, 0x8c, 0x3c, 0x15, 0xad, 0x2d, 0x1e, 0x33, 0x09, 0x58, 0x93, 0xb4, 0x29, 0x3a, 0xbc, 0x6f, 0x7d,
    0x51, 0x3b, 0x5b, 0x97, 0xfe, 0x67, 0xe1, 0x9e, 0xff, 0x6b, 0xdc, 0xf2, 0xb0, 0x6f, 0xa1, 0x4e, 0x4b, 0xf2, 0xdf, 0xd6,
    0xa4, 0xec, 0x8d, 0x19, 0x6d, 0x30, 0x67, 0xde, 0x04, 0x5e, 0xaf, 0xd7, 0xd4, 0x42, 0xf8, 0xbc, 0xca, 0xfc, 0x49, 0xc0,
    0xe7, 0xcd, 0xfc, 0xab, 0xca, 0x3f, 0x67, 0xff, 0xfb, 0x41, 0xc0, 0xe4, 0xe8, 0x0c, 0xe8, 0x2e, 0xca, 0x43, 0xfb, 0xec,
    0xe0, 0xeb, 0xea, 0x30, 0x14, 0xca, 0x30, 0x8d, 0x49, 0xaa, 0x99, 0x71, 0xcb, 0x85, 0xa4, 0x68, 0xda, 0xd1, 0xbe, 0xa9,
    0xc6, 0xee, 0x26, 0xdf, 0x3f, 0xde, 0x39, 0x29, 0x6c, 0x45, 0x9e, 0x41, 0x88, 0x63, 0xd8, 0x31, 0x47, 0x8e, 0xdc, 0xc8,
    0xe4, 0x28, 0x25, 0x75, 0x11, 0x99, 0xdd, 0x28, 0x25, 0xa7, 0x5e, 0xac, 0x7f, 0x0c, 0xb5, 0x2b, 0x62, 0x9d, 0xe0, 0xda,
    0xe3, 0xc2, 0xd8, 0x8d, 0xc6, 0x25, 0x5f, 0x08, 0x6e, 0xfc, 0xcd, 0xae, 0x4c, 0x99, 0x41, 0xc4, 0x75, 0x3e, 0x5e, 0x51,
    0xa1, 0x76, 0x47, 0x93, 0x4a, 0x83, 0x51, 0x91, 0xf3, 0x92, 0xd0, 0x29, 0xa6, 0x44, 0x3c, 0x2a, 0x91, 0x3f, 0x01, 0x75,
    0xeb, 0x6f, 0xf3, 0x3c, 0x04, 0xd3, 0x74, 0x7a, 0xfc, 0x7a, 0x39, 0x70, 0xc8, 0x3a, 0x89, 0x93, 0xbd, 0xfd, 0xd7, 0x41,
    0x2c, 0xb0, 0xd3, 0xef, 0xd0, 0xd5, 0x75, 0x24, 0xb1, 0x0e, 0x3d, 0x89, 0x8e, 0xde, 0xa7, 0x40, 0x80, 0xd2, 0x05, 0xe5,
    0x18, 0xa2, 0xf3, 0x30, 0x22, 0x56, 0x0b, 0xbc, 0x05, 0xb0, 0x48, 0x9a, 0x42, 0xb7, 0xe1, 0x32, 0xba, 0x52, 0x99, 0x22,
    0xf6, 0x30, 0x82, 0x05, 0x68, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x07, 0x01, 0xa0, 0x82, 0x05, 0x59,
    0x04, 0x82, 0x05, 0x55, 0x30, 0x82, 0x05, 0x51, 0x30, 0x82, 0x05, 0x4d, 0x06, 0x0b, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d,
    0x01, 0x0c, 0x0a, 0x01, 0x02, 0xa0, 0x82, 0x04, 0xee, 0x30, 0x82, 0x04, 0xea, 0x30, 0x1c, 0x06, 0x0a, 0x2a, 0x86, 0x48,
    0x86, 0xf7, 0x0d, 0x01, 0x0c, 0x01, 0x03, 0x30, 0x0e, 0x04, 0x08, 0x8e, 0x7e, 0x90, 0x94, 0xaf, 0x09, 0xc5, 0xbc, 0x02,
    0x02, 0x08, 0x00, 0x04, 0x82, 0x04, 0xc8, 0x0c, 0x7c, 0x7f, 0x58, 0x8b, 0x41, 0x9a, 0xb8, 0x70, 0xbf, 0x6c, 0x4c, 0xb8,
    0x7d, 0x72, 0xa5, 0x50, 0xe6, 0xc4, 0xaf, 0x74, 0x0e, 0x88, 0xbf, 0x83, 0x51, 0xbc, 0xe1, 0x66, 0x8a, 0x9f, 0x42, 0x11,
    0x2b, 0x3d, 0x8c, 0x10, 0xa3, 0xc2, 0xdf, 0xb9, 0x36, 0x74, 0xc1, 0x18, 0x23, 0x1e, 0x9a, 0xbf, 0x8d, 0x0a, 0x4b, 0x63,
    0xd5, 0x20, 0x1b, 0xae, 0xb0, 0x64, 0xfc, 0xe1, 0x5c, 0xe7, 0xde, 0xa3, 0x6f, 0x8e, 0xe3, 0xc9, 0x8d, 0x18, 0x63, 0x7f,
    0x26, 0x4a, 0x3d, 0x41, 0x76, 0xa6, 0xaa, 0x3f, 0x27, 0x75, 0xec, 0x2f, 0x78, 0xd2, 0x40, 0x28, 0xe7, 0xf5, 0xee, 0x61,
    0x6d, 0x49, 0xe0, 0x64, 0x33, 0xc9, 0x9e, 0xf6, 0xda, 0x86, 0x3a, 0xad, 0x47, 0x13, 0xe2, 0x8a, 0x0b, 0x98, 0xe7, 0x73,
    0xea, 0x08, 0x59, 0xfe, 0x74, 0x6f, 0x10, 0x7d, 0xbc, 0x0b, 0xb9, 0xcf, 0xe7, 0xe7, 0x28, 0xe8, 0xfe, 0x20, 0x8a, 0x98,
    0x40, 0x00, 0x52, 0xa0, 0x0c, 0x5c, 0xfa, 0x48, 0x5b, 0xf4, 0x3c, 0x76, 0x5d, 0xf4, 0x33, 0x53, 0xd4, 0x51, 0x43, 0x47,
    0x29, 0xda, 0xff, 0xbd, 0xfe, 0x71, 0x5b, 0x50, 0xa1, 0xa5, 0x25, 0xe9, 0xcc, 0x68, 0x74, 0x9f, 0x7f, 0x39, 0x65, 0x5e,
    0xb9, 0x71, 0x8f, 0x25, 0x68, 0xe6, 0x71, 0x06, 0x10, 0xa2, 0xfb, 0x08, 0x54, 0x21, 0xca, 0x28, 0xfc, 0xf1, 0x89, 0xb9,
    0x29, 0x11, 0x67, 0x00, 0x19, 0xdd, 0x00, 0xd8, 0x48, 0x89, 0x46, 0x0d, 0x39, 0x0c, 0x7e, 0x94, 0x02, 0x80, 0x37, 0xa0,
    0x01, 0x45, 0x25, 0xbd, 0x8b, 0x44, 0xcc, 0xdf, 0x43, 0xa1, 0x1d, 0xf5, 0x59, 0x4b, 0x07, 0xe6, 0xab, 0x15, 0x93, 0x3d,
    0xea, 0x7d, 0xd6, 0xaa, 0xb0, 0x97, 0xed, 0x1d, 0x5e, 0xc2, 0xf0, 0xea, 0x1b, 0xc2, 0xcc, 0x88, 0x47, 0x3e, 0xe4, 0x54,
    0xc3, 0x02, 0xac, 0x5e, 0x88, 0xb9, 0x2f, 0x82, 0xd4, 0xd0, 0x5d, 0xb2, 0x2a, 0xee, 0x94, 0x3d, 0xdb, 0x82, 0x93, 0xc6,
    0x69, 0x5f, 0x40, 0x83, 0xf0, 0x07, 0x8d, 0x9f, 0x7f, 0x29, 0x3f, 0x4d, 0x3b, 0x08, 0xd9, 0x29, 0xf5, 0x1c, 0x0f, 0x18,
    0x42, 0x4b, 0xd9, 0x01, 0xda, 0x71, 0x92, 0xa8, 0x32, 0xa7, 0x53, 0x6f, 0xd0, 0x74, 0x4a, 0xee, 0x39, 0x04, 0xf1, 0x2d,
    0xee, 0x50, 0xbe, 0x48, 0xb1, 0x90, 0x21, 0x24, 0x28, 0x40, 0xa9, 0x85, 0xe1, 0x81, 0x77, 0x37, 0xa8, 0x86, 0x15, 0x7d,
    0x16, 0xb2, 0xe7, 0xcc, 0xe0, 0xa2, 0x7e, 0x58, 0xb3, 0xdc, 0xf9, 0x41, 0xae, 0x36, 0xba, 0x55, 0x87, 0x64, 0x01, 0xfd,
    0xc9, 0x0e, 0xa1, 0xfe, 0x55, 0xc3, 0x2a, 0x66, 0xd5, 0x83, 0x39, 0x7e, 0x5a, 0xe8, 0x28, 0x76, 0x36, 0xbb, 0x39, 0xa9,
    0xb7, 0xc6, 0xcf, 0x99, 0x56, 0xe5, 0xbf, 0x4d, 0xb2, 0xa0, 0xac, 0x64, 0x00, 0xc9, 0x42, 0x79, 0x47, 0x46, 0xd7, 0x9c,
    0x4a, 0x33, 0x03, 0x55, 0x07, 0x7f, 0x05, 0x23, 0xe3, 0x51, 0x35, 0xa9, 0x32, 0xe9, 0xa6, 0xf2, 0xe2, 0x42, 0x4d, 0x00,
    0xbb, 0xdb, 0xc3, 0x85, 0x05, 0xcb, 0xe4, 0xb1, 0x0a, 0x03, 0xf4, 0xe5, 0x27, 0x28, 0x12, 0xec, 0x1e, 0xd4, 0xd7, 0x43,
    0xe3, 0x05, 0xc7, 0x92, 0xd2, 0x8e, 0xf7, 0xae, 0x55, 0x1a, 0x50, 0x88, 0x2f, 0x91, 0x05, 0x65, 0x4b, 0xe3, 0xba, 0xc0,
    0x42, 0x86, 0x19, 0x2b, 0x64, 0xfc, 0x46, 0x31, 0x9b, 0xd2, 0x88, 0x32, 0xf8, 0x4d, 0x91, 0xd4, 0xc6, 0x77, 0xcb, 0x29,
    0x00, 0x5e, 0xd2, 0x48, 0x99, 0x0e, 0x3f, 0x2d, 0x4f, 0xdb, 0x9b, 0x05, 0xea, 0xa1, 0x3d, 0x9f, 0x21, 0x83, 0x6f, 0xcf,
    0xe9, 0x1c, 0x65, 0x40, 0x3c, 0x8b, 0x2a, 0x38, 0x8f, 0x1b, 0x5a, 0x3c, 0x73, 0x7a, 0xfc, 0x81, 0x69, 0xb3, 0xff, 0xb6,
    0x25, 0x12, 0x3f, 0xda, 0x50, 0xe7, 0xde, 0xfe, 0xd3, 0x31, 0x2f, 0xb4, 0x99, 0x87, 0xae, 0x17, 0xaf, 0xe4, 0xb8, 0x35,
    0xf7, 0x3c, 0xc0, 0x99, 0x0e, 0x75, 0x72, 0xb6, 0x46, 0xa1, 0x55, 0xef, 0xff, 0x48, 0x3b, 0x5c, 0x85, 0xf7, 0xc3, 0x03,
    0x0a, 0x49, 0x0f, 0x11, 0x48, 0x13, 0x8b, 0x90, 0x73, 0x33, 0xb6, 0x22, 0x35, 0x45, 0x07, 0x80, 0x1a, 0xf9, 0x91, 0x80,
    0x9d, 0x8b, 0xc7, 0x8e, 0xcc, 0x3a, 0x52, 0x93, 0x8f, 0xf6, 0x59, 0x3c, 0x69, 0xf7, 0x52, 0x9a, 0x8d, 0x8e, 0xfe, 0x8a,
    0x41, 0xb0, 0x43, 0x74, 0x04, 0xe8, 0x0e, 0xf5, 0xc1, 0x4c, 0xa3, 0x8d, 0xe3, 0x98, 0x25, 0xf6, 0xd5, 0x0d, 0xa9, 0x2d,
    0xb7, 0x6f, 0x52, 0x22, 0x43, 0x59, 0x30, 0x6d, 0x54, 0xb6, 0xad, 0x73, 0xa1, 0xe8, 0xee, 0x10, 0xbd, 0x55, 0xa4, 0x7f,
    0xc3, 0x1d, 0xad, 0x8e, 0x72, 0xf1, 0x26, 0x6d, 0xa1, 0xaf, 0xda, 0x82, 0x37, 0xa1, 0x6d, 0xfe, 0x78, 0xd1, 0x88, 0x65,
    0x6a, 0xb2, 0x33, 0x23, 0xcd, 0xba, 0xbe, 0x09, 0x66, 0x61, 0x33, 0xdc, 0x69, 0xed, 0x4f, 0xe6, 0xfb, 0x2f, 0x7d, 0xd0,
    0xfd, 0x7a, 0x21, 0x69, 0x2d, 0x1f, 0xd4, 0xc4, 0x93, 0x7c, 0x34, 0x7d, 0x67, 0x2c, 0xe9, 0x2a, 0x9a, 0x53, 0xc2, 0xbf,
    0xf9, 0x06, 0x10, 0xa6, 0xa8, 0x60, 0xe3, 0x01, 0xcb, 0x2b, 0x03, 0xdb, 0xb7, 0x27, 0xe9, 0x86, 0xe8, 0x7d, 0x75, 0xce,
    0x80, 0xdb, 0xaf, 0xe9, 0x7e, 0x75, 0xad, 0xe3, 0xd4, 0xc4, 0xf3, 0x10, 0x89, 0x16, 0xcb, 0xc6, 0x23, 0x5a, 0x58, 0x66,
    0xb6, 0x2a, 0xd7, 0xc9, 0x69, 0xd3, 0x7f, 0xa2, 0x9a, 0x5c, 0x1c, 0xd4, 0xf8, 0xe3, 0xe0, 0x63, 0x01, 0x88, 0x14, 0xb3,
    0x20, 0xe3, 0x22, 0x45, 0x3d, 0xae, 0xaf, 0x0b, 0x55, 0xa1, 0x65, 0xec, 0x16, 0x0b, 0x35, 0x37, 0x6f, 0x12, 0x5f, 0x29,
    0x47, 0xee, 0xdd, 0xbb, 0xcf, 0x9f, 0x87, 0xaf, 0x7d, 0xaa, 0xf4, 0x01, 0x45, 0xea, 0x5f, 0x00, 0x87, 0x1e, 0xeb, 0x2f,
    0x77, 0x2b, 0x92, 0x42, 0x04, 0x45, 0x33, 0xf2, 0xfb, 0x6b, 0xac, 0xca, 0x98, 0x79, 0x56, 0x6f, 0xe7, 0x5b, 0xbd, 0x63,
    0xc7, 0x3a, 0x8c, 0xfd, 0x93, 0xb1, 0x13, 0x4e, 0xc2, 0x05, 0x7f, 0xde, 0x44, 0xa8, 0xb7, 0xc4, 0x9c, 0xba, 0x57, 0x58,
    0x3b, 0xba, 0xb5, 0x74, 0x73, 0x97, 0x20, 0x53, 0x70, 0x70, 0x65, 0xf1, 0x81, 0xea, 0x07, 0xc2, 0xbe, 0x57, 0x71, 0x62,
    0x3b, 0xc0, 0x3c, 0x07, 0x65, 0xf4, 0x22, 0xfb, 0xd3, 0xf9, 0x2d, 0xb3, 0x20, 0xdd, 0x66, 0x51, 0x89, 0x54, 0x57, 0xcd,
    0xd7, 0xc7, 0x1a, 0xd9, 0xfe, 0xe0, 0x13, 0x9d, 0x7d, 0xe7, 0xe3, 0x2f, 0x65, 0x3e, 0xf0, 0xb2, 0xd9, 0x0c, 0x1a, 0xa9,
    0xaa, 0xba, 0x3b, 0x79, 0x86, 0xed, 0x6c, 0xbf, 0x9e, 0x9b, 0xb5, 0x78, 0xd8, 0x9e, 0x2f, 0x95, 0xcc, 0x31, 0xb4, 0x5f,
    0xd3, 0x63, 0xff, 0xb9, 0x62, 0x34, 0xfd, 0x78, 0x1f, 0xac, 0xe7, 0xbd, 0x29, 0x09, 0x2a, 0x1c, 0x94, 0xc5, 0x28, 0x6c,
    0x04, 0x59, 0xeb, 0xd6, 0x7c, 0x0d, 0x45, 0x07, 0xd9, 0xde, 0x89, 0xa1, 0xd8, 0x38, 0x8a, 0x2b, 0x9f, 0xc3, 0xdb, 0x55,
    0x89, 0x90, 0xc6, 0x75, 0xd0, 0x2f, 0x85, 0x9b, 0x0a, 0x5e, 0x04, 0xa1, 0xf9, 0xf7, 0x16, 0x35, 0x9d, 0x97, 0xfe, 0x7c,
    0x4b, 0x27, 0x4c, 0xc3, 0x8a, 0x2a, 0x56, 0x6a, 0x41, 0xe5, 0xd3, 0x82, 0xeb, 0xd2, 0x62, 0x4e, 0x11, 0x1e, 0x4e, 0xae,
    0xa4, 0x79, 0x89, 0x20, 0x82, 0x6e, 0x39, 0x7d, 0x70, 0xf8, 0x17, 0xd6, 0xe3, 0x67, 0x9a, 0x14, 0xd7, 0xc8, 0x80, 0xbe,
    0x62, 0x52, 0xe7, 0x69, 0xab, 0x98, 0xa9, 0x14, 0x98, 0xbd, 0x30, 0xf4, 0xab, 0x2c, 0x22, 0x6b, 0x5f, 0xee, 0x58, 0xf3,
    0x6f, 0x15, 0xea, 0xce, 0xd3, 0x1b, 0x07, 0xfa, 0xe6, 0x4c, 0xeb, 0xeb, 0x30, 0xa6, 0xff, 0x03, 0xc9, 0x75, 0x94, 0xa5,
    0x5b, 0x68, 0xd3, 0x42, 0x85, 0x3f, 0xa4, 0x87, 0xee, 0x3f, 0x14, 0x63, 0x16, 0x52, 0x26, 0x3b, 0x1a, 0xee, 0x48, 0x77,
    0x6e, 0x4a, 0x56, 0x01, 0x53, 0x54, 0x1b, 0xa6, 0xd7, 0x72, 0x98, 0x89, 0xd5, 0xf7, 0x11, 0x3a, 0x86, 0xac, 0x64, 0xe6,
    0x59, 0xba, 0x07, 0xea, 0x23, 0x21, 0x05, 0xd6, 0x14, 0xed, 0x88, 0x2e, 0x96, 0xb3, 0x90, 0xc3, 0xb7, 0xc4, 0x5b, 0x8f,
    0x0e, 0xcd, 0x56, 0xba, 0xb8, 0x4b, 0x7b, 0xfd, 0xd4, 0x7d, 0x0c, 0xcb, 0xe1, 0xff, 0xaf, 0x3e, 0x2a, 0x7c, 0x1a, 0xe5,
    0x66, 0x65, 0x59, 0x42, 0xd7, 0x3b, 0xd2, 0x2e, 0x89, 0x1d, 0x64, 0xc0, 0xbd, 0xec, 0x8c, 0xaa, 0x06, 0xb8, 0x5a, 0x7c,
    0xb8, 0xd0, 0xa5, 0xef, 0x5a, 0xf3, 0x92, 0x4c, 0x2f, 0x60, 0x98, 0x34, 0x73, 0x49, 0x92, 0x7a, 0x5d, 0x7c, 0x2c, 0xcd,
    0x0b, 0xfb, 0x28, 0xd9, 0x3e, 0xfa, 0xbd, 0x76, 0x0f, 0xaa, 0x71, 0xfa, 0x98, 0x36, 0x94, 0x97, 0xaa, 0x97, 0x1f, 0x34,
    0x21, 0x72, 0xc6, 0x19, 0xb4, 0xe3, 0xaa, 0x05, 0x16, 0xda, 0xaa, 0x92, 0x04, 0x49, 0xc7, 0x97, 0x42, 0x58, 0xd0, 0x80,
    0xdc, 0x9e, 0xcf, 0xfa, 0x5f, 0x4b, 0xbc, 0x78, 0xff, 0x95, 0x39, 0x31, 0x4c, 0x30, 0x25, 0x06, 0x09, 0x2a, 0x86, 0x48,
    0x86, 0xf7, 0x0d, 0x01, 0x09, 0x14, 0x31, 0x18, 0x1e, 0x16, 0x00, 0x74, 0x00, 0x65, 0x00, 0x73, 0x00, 0x74, 0x00, 0x5f,
    0x00, 0x69, 0x00, 0x6d, 0x00, 0x70, 0x00, 0x6f, 0x00, 0x72, 0x00, 0x74, 0x30, 0x23, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x09, 0x15, 0x31, 0x16, 0x04, 0x14, 0xf6, 0x4d, 0x65, 0x40, 0x9d, 0xff, 0x26, 0x84, 0x3f, 0x6e, 0x6b,
    0x99, 0x75, 0xb0, 0xae, 0x60, 0x01, 0x8c, 0xf0, 0xf9, 0x30, 0x30, 0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03,
    0x02, 0x1a, 0x05, 0x00, 0x04, 0x14, 0x3d, 0xbb, 0x58, 0x44, 0x6c, 0xa3, 0x3c, 0x48, 0xaa, 0x52, 0x76, 0xd1, 0xef, 0x3a,
    0xe2, 0xa4, 0x23, 0xcc, 0x4d, 0x38, 0x04, 0x08, 0x11, 0xa4, 0xda, 0x79, 0x3e, 0xdd, 0xba, 0xfa, 0x02, 0x01, 0x01
};
unsigned int test_import_p12_len = 2499;

// test_import_p12's password: "password"

static void
verifyPrivateKeyExtractability(BOOL extractable, NSArray *items)
{
	// After importing items, check that private keys (if any) have
	// the expected extractable attribute value.

	CFIndex count = [items count];
    is(count, 1, "One identity added");

	for (id item in items)
	{
		OSStatus status;
		SecKeyRef aKey = NULL;
		if (SecKeyGetTypeID() == CFGetTypeID((CFTypeRef)item)) {
			aKey = (SecKeyRef) CFRetain((CFTypeRef)item);
			fprintf(stdout, "Verifying imported SecKey\n");
		}
		else if (SecIdentityGetTypeID() == CFGetTypeID((CFTypeRef)item)) {
			status = SecIdentityCopyPrivateKey((SecIdentityRef)item, &aKey);
            ok_status(status, "%s: SecIdentityCopyPrivateKey", testName);
		}

        ok(aKey, "%s: Have a key to test", testName);

		if (aKey)
		{
			const CSSM_KEY *cssmKey;
			OSStatus status = SecKeyGetCSSMKey(aKey, &cssmKey);
            ok_status(status, "%s: SecKeyGetCSSMKey", testName);
			if (status != noErr) {
				continue;
			}
            is(cssmKey->KeyHeader.KeyClass, CSSM_KEYCLASS_PRIVATE_KEY, "%s: key is private key", testName);

			if (!(cssmKey->KeyHeader.KeyClass == CSSM_KEYCLASS_PRIVATE_KEY)) {
				fprintf(stdout, "Skipping non-private key (KeyClass=%d)\n", cssmKey->KeyHeader.KeyClass);
				continue; // only checking private keys
			}
			BOOL isExtractable = (cssmKey->KeyHeader.KeyAttr & CSSM_KEYATTR_EXTRACTABLE) ? YES : NO;
            is(isExtractable, extractable, "%s: key extractability matches expectations", testName);

			CFRelease(aKey);
		}
	}
}

static void
setIdentityPreferenceForImportedIdentity(SecKeychainRef importKeychain, NSString *name, NSArray *items)
{
    CFArrayRef importedItems = (__bridge CFArrayRef)items;

    if (importedItems)
    {
        SecIdentityRef importedIdRef = NULL;
        CFIndex dex, numItems = CFArrayGetCount(importedItems);
        for(dex=0; dex<numItems; dex++)
        {
            CFTypeRef item = CFArrayGetValueAtIndex(importedItems, dex);
            if(CFGetTypeID(item) == SecIdentityGetTypeID())
            {
                OSStatus status = noErr;
                importedIdRef = (SecIdentityRef)item;

                status = SecIdentitySetPreference(importedIdRef, (CFStringRef)name, (CSSM_KEYUSE)0);
                ok_status(status, "%s: SecIdentitySetPreference", testName);
                break;
            }
        }
        ok(importedIdRef, "%s: identity found?", testName);
    }
    else
    {
        fail("%s: no items passed to setIdentityPreferenceForImportedIdentity", testName);
        pass("test numbers match");
    }
}

static void removeIdentityPreference(bool test) {
    // Clean up the identity preference, since it's in the default keychain
    CFMutableDictionaryRef q = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(q, kSecClass, kSecClassGenericPassword);
    q = addLabel(q, CFSTR("kc-28-p12-import@apple.com"));

    if(test) {
        ok_status(SecItemDelete(q), "%s: SecItemDelete (identity preference)", testName);
    } else {
        // Our caller doesn't care if this works or not.
        SecItemDelete(q);
    }
    CFReleaseNull(q);
}


static OSStatus
testP12Import(BOOL extractable, SecKeychainRef keychain, const char *p12Path, CFStringRef password, bool useDeprecatedAPI)
{
	OSStatus status = paramErr;

	NSString *file = [NSString stringWithUTF8String:p12Path];
	NSData *p12Data = [[NSData alloc] initWithContentsOfFile:file];
	NSArray *keyAttrs = nil;
	CFArrayRef outItems = nil;

	SecExternalFormat externFormat = kSecFormatPKCS12;
	SecExternalItemType	itemType = kSecItemTypeAggregate; // certificates and keys

	// Decide which parameter structure to use.
	SecKeyImportExportParameters keyParamsOld;	// for SecKeychainItemImport, deprecated as of 10.7
	SecItemImportExportKeyParameters keyParamsNew; // for SecItemImport, 10.7 and later

	void *keyParamsPtr = (useDeprecatedAPI) ? (void*)&keyParamsOld : (void*)&keyParamsNew;

	if (useDeprecatedAPI) // SecKeychainItemImport, deprecated as of 10.7
	{
		SecKeyImportExportParameters *keyParams = (SecKeyImportExportParameters *)keyParamsPtr;
		memset(keyParams, 0, sizeof(SecKeyImportExportParameters));
		keyParams->version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
        keyParams->passphrase = password;
		if (!extractable)
		{
			// explicitly set the key attributes, omitting the CSSM_KEYATTR_EXTRACTABLE bit
			keyParams->keyAttributes = CSSM_KEYATTR_PERMANENT | CSSM_KEYATTR_SENSITIVE;
		}
	}
	else // SecItemImport, 10.7 and later (preferred interface)
	{
		SecItemImportExportKeyParameters *keyParams = (SecItemImportExportKeyParameters *)keyParamsPtr;
		memset(keyParams, 0, sizeof(SecItemImportExportKeyParameters));
		keyParams->version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
        keyParams->passphrase = password;
		if (!extractable)
		{
			// explicitly set the key attributes, omitting kSecAttrIsExtractable
			keyAttrs = [[NSArray alloc] initWithObjects: (id) kSecAttrIsPermanent, kSecAttrIsSensitive, nil];
			keyParams->keyAttributes = (__bridge_retained CFArrayRef) keyAttrs;
		}
	}

    if (useDeprecatedAPI) // SecKeychainItemImport, deprecated as of 10.7
    {
        status = SecKeychainItemImport((CFDataRef)p12Data,
                                        NULL,
                                        &externFormat,
                                        &itemType,
                                        0,		/* flags not used (yet) */
                                        keyParamsPtr,
                                        keychain,
                                        (CFArrayRef*)&outItems);
        ok_status(status, "%s: SecKeychainItemImport", testName);
    }
    else // SecItemImport
    {
        status = SecItemImport((CFDataRef)p12Data,
                                        NULL,
                                        &externFormat,
                                        &itemType,
                                        0,		/* flags not used (yet) */
                                        keyParamsPtr,
                                        keychain,
                                        (CFArrayRef*)&outItems);
        ok_status(status, "%s: SecItemImport", testName);
    }

	verifyPrivateKeyExtractability(extractable, (__bridge NSArray*) outItems);

    checkN(testName, createQueryKeyDictionaryWithLabel(keychain, kSecAttrKeyClassPrivate, CFSTR("test_import")), 1);
    checkN(testName, addLabel(makeBaseQueryDictionary(keychain, kSecClassCertificate), CFSTR("test_import")), 1);

    setIdentityPreferenceForImportedIdentity(keychain, @"kc-28-p12-import@apple.com", (__bridge NSArray*) outItems);

    deleteItems(outItems);

    CFReleaseNull(outItems);

	return status;
}

int kc_28_p12_import(int argc, char *const *argv)
{
    plan_tests(70);
    initializeKeychainTests(__FUNCTION__);

    SecKeychainRef kc = getPopulatedTestKeychain();

    removeIdentityPreference(false); // if there's still an identity preference in the keychain, we'll get prompts. Delete it pre-emptively (but don't test about it)

    writeFile(keychainTempFile, test_import_p12, test_import_p12_len);
    testP12Import(true, kc, keychainTempFile, CFSTR("password"), false);
    testP12Import(true, kc, keychainTempFile, CFSTR("password"), true);

    testP12Import(false, kc, keychainTempFile, CFSTR("password"), false);
    testP12Import(false, kc, keychainTempFile, CFSTR("password"), true);

    ok_status(SecKeychainDelete(kc), "%s: SecKeychainDelete", testName);
    CFReleaseNull(kc);

    removeIdentityPreference(true);

    checkPrompts(0, "No prompts while importing items");

    deleteTestFiles();
	return 0;
}