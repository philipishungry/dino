Name:       dino
Version:    0.1.0
Release:    1%{?dist}

License:    GPLv3
Summary:    Modern XMPP ("Jabber") Chat Client using GTK+/Vala
URL:        https://github.com/philipishungry/dino
Source0:    %{url}/archive/308db53bc5a8fa44f66c0a8668384d3e5b592ce7.tar.gz

BuildRequires: cmake
BuildRequires: desktop-file-utils
BuildRequires: gcc
BuildRequires: gcc-c++
BuildRequires: gpgme-devel
BuildRequires: gnupg2
BuildRequires: gtk+-devel
BuildRequires: gtk3-devel
BuildRequires: libgee-devel
BuildRequires: libgcrypt-devel
BuildRequires: libsignal-protocol-c-devel
BuildRequires: libsoup-devel
BuildRequires: ninja-build
BuildRequires: qrencode-devel
BuildRequires: sqlite-devel
BuildRequires: vala

Requires:   filesystem
Requires:   hicolor-icon-theme


%description
A modern XMPP ("Jabber") chat client using GTK+/Vala.


%package devel
Summary:    Development files for dino

Requires:   dino%{?_isa} == %{version}-%{release}


%description devel
Development files for dino.


%prep
%setup -q -n %{name}-%{version}

# Remove the bundled library
rm .gitmodules
rm -r plugins/signal-protocol/libsignal-protocol-c


%build
# Use the system version of libsignal-protocol-c instead of the bundled one.
export SHARED_SIGNAL_PROTOCOL=true
%configure
%make_build


%install
%make_install
%find_lang %{name}
%find_lang %{name}-omemo
%find_lang %{name}-openpgp


%check
make test
desktop-file-validate %{buildroot}/%{_datadir}/applications/im.dino.Dino.desktop


%files -f %{name}.lang -f %{name}-omemo.lang -f %{name}-openpgp.lang
%license LICENSE
%doc README.md
%{_bindir}/dino
%{_datadir}/applications/im.dino.Dino.desktop
%{_datadir}/dbus-1/services/im.dino.Dino.service
%{_datadir}/icons/hicolor/scalable/apps/im.dino.Dino.svg
%{_datadir}/icons/hicolor/scalable/status/*.svg
%{_datadir}/icons/hicolor/symbolic/apps/im.dino.Dino-symbolic.svg
%{_datadir}/metainfo/im.dino.Dino.appdata.xml
%{_libdir}/dino
%{_libdir}/libdino.so.0*
%{_libdir}/libqlite.so.0*
%{_libdir}/libxmpp-vala.so.0*


%files devel
%{_datadir}/vala/vapi/dino.*
%{_datadir}/vala/vapi/qlite.*
%{_datadir}/vala/vapi/xmpp-vala.*
%{_includedir}/dino.h
%{_includedir}/dino_i18n.h
%{_includedir}/qlite.h
%{_includedir}/xmpp-vala.h
%{_libdir}/libdino.so
%{_libdir}/libqlite.so
%{_libdir}/libxmpp-vala.so


%changelog
* Fri Jan 31 2020 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.1.0-1
- Update to the first Dino release.
- https://dino.im/blog/2020/01/dino-0.1-release/
- https://github.com/dino/dino/compare/11c18cdf...v0.1.0

* Tue Dec 17 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.15.20191216.git.11c18cdf
- Update to 11c18cdf.
- https://github.com/dino/dino/compare/d194eae6...11c18cdf

* Sat Nov 30 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.14.20191129.git.d194eae6
- Update to d194eae6.
- https://github.com/dino/dino/compare/f746ce74...d194eae6

* Mon Sep 23 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.13.20190917.git.f746ce74
- Update to f746ce74.
- https://github.com/dino/dino/compare/a96c8014...f746ce74

- Update to a96c8014.
- Fixes CVE-2019-16235 (#1751847), CVE-2019-16236 (#1751849), and CVE-2019-16237 (#1751851).
- https://github.com/dino/dino/compare/016ab2c1...a96c8014

* Sat Aug 31 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.12.20190830.git.016ab2c1
- Update to 016ab2c1.
- https://github.com/dino/dino/compare/8120203d...016ab2c1

* Mon Jun 03 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.9.20190601.git.8120203d
- Correct the commit date in the Release field, it was a typo in the prior commit.

* Sat Jun 01 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.8.20190701.git.git.8120203d
- Update to 8120203d.
- https://github.com/dino/dino/compare/f4778ef3...8120203d

* Sun May 05 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.7.20190429.git.f4778ef3
- Update to f4778ef3.
- https://github.com/dino/dino/compare/330649a...f4778ef3

* Sat Apr 06 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.6.20190316.git.330649a
- Update to 330649a.
- https://github.com/dino/dino/compare/a493269...330649a

* Sat Mar 16 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.5.20190314.git.a493269
- Update to a493269.
- Unbundle libsignal-protocol-c.

* Sun Feb 24 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.4.20190116.git.8e14ac6
- Do not rename zh_Hans to zh-Hans.
- https://github.com/dino/dino/issues/524

* Wed Feb 13 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.3.20190116.git.8e14ac6
- Add the commit date into the Release field.
- Correct the license to GPLv3 (not GPLv3+).
- Move the unversioned shared object to the -devel package.
- Use the find_lang macro.
- Use desktop-file-validate in the check section.

* Tue Jan 29 2019 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.2.8e14ac6
- Upgrade to 8e14ac6.

* Sat Dec 29 2018 Randy Barlow <bowlofeggs@fedoraproject.org> - 0.0-0.1.4209428
- Initial release.
