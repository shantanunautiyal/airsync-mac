//
//  LicenseView.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2025-07-31.
//

import SwiftUI

struct LicenseView: View {
    var body: some View {
        VStack{
            // Expandable license sections
            ExpandableLicenseSection(title: "Library: AirSync License", content: """
Mozilla Public License Version 2.0
==================================

This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.  
If a copy of the MPL was not distributed with this file, You can obtain one at https://www.mozilla.org/MPL/2.0/.

-------------------------------------------------------------------
Additional Terms: Non-Commercial Use Clause
-------------------------------------------------------------------

In addition to the terms of the Mozilla Public License 2.0, the following restrictions apply:

1. **Non-Commercial Use Only**  
   You may use, modify, and build this software solely for **personal, non-commercial purposes**.  
   You may not use, distribute, sublicense, or offer any version of this software (modified or unmodified) for **commercial purposes**, including but not limited to:

   - Selling or licensing the software or any derivative work
   - Hosting the software as part of a paid service
   - Distributing it bundled in a commercial product or service

2. **Commercial Use Requires Permission**  
   Commercial use requires a **separate commercial license agreement** with the original author.  
   Contact the author at: sameerasw.com@gmail.com for licensing options.

3. **No Trademark Rights**  
   This license does not grant any rights to use the project name, logo, or branding for commercial or promotional use.

4. **Preservation of this Clause**  
   This Non-Commercial Use clause must be included in all copies or substantial portions of the Software.

-------------------------------------------------------------------
END OF ADDITIONAL TERMS
-------------------------------------------------------------------

""")

            ExpandableLicenseSection(title: "AirSync+ Commercial Eula", content: """
Commercial End User License Agreement (EULA)
============================================

This End User License Agreement (the “Agreement”) is a legal agreement between you (either an individual or a legal entity) and Sameera Wijerathna for the use of the AirSync (2.0) application (the “Software”).

By using or installing the Software, you agree to be bound by the terms of this Agreement.

1. GRANT OF LICENSE  
You are granted a non-exclusive, non-transferable license to use the Software for personal or commercial purposes, according to your purchase terms or subscription plan.

2. RESTRICTIONS  
You may not:
- Modify, reverse engineer, or redistribute the Software.
- Rent, lease, or sell access to the Software without permission.
- Use the Software to create a competing product.

3. OWNERSHIP  
All rights, title, and interest in the Software remain with the original developer.

4. TERMINATION  
This license is effective until terminated. It will terminate automatically without notice if you fail to comply with any term. Upon termination, you must delete all copies of the Software.

5. DISCLAIMER  
This Software is provided “as is,” without warranty of any kind. In no event shall the author be liable for any damages arising from the use of the Software.

For commercial licensing or custom use cases, contact: sameerasw.com@gmail.com

© 2025 sameerasw.com. All Rights Reserved.

""")
            ExpandableLicenseSection(title: "Library: QRCode License", content: """
MIT License

Copyright (c) 2025 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
""")
            ExpandableLicenseSection(title: "Library: Swifter", content: """
Copyright (c) 2014, Damian Kołakowski
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the {organization} nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
""")
            ExpandableLicenseSection(title: "Library: GumroadLicenseValidator", content: """
The MIT License (MIT)

Copyright (c) 2022 Daniel Kasaj

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

""")
        }
    }
}

#Preview {
    LicenseView()
}

struct ConnectionInfoText: View {
    var label: String
    var icon: String
    var text: String

    var body: some View {
        HStack{
            Label(label, systemImage: icon)
            Spacer()
            Text(text)
        }
        .padding(1)
    }
}
