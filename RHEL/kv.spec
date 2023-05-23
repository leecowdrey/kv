Name:           kv
Version:        1.0.3
Release:        1%{?dist}
Summary:        BASH Key-Value Store

License:        EPL
URL:            https://github.com/leecowdrey/kv
BuildRoot:      ~/rpmbuild/

BuildArch:      noarch
Requires:       bash
Requires:       tree
Requires:       sed
Requires:       bc
Requires:       openssl
Requires:	uuid

%description
BASH Key-Value Store

%prep

%build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{name}
mkdir -p /run/%{name}
install -m 0555 ./%{name}%{_bindir}%{name} %{buildroot}%{_bindir}/

%clean

%files
%defattr (-, root, bin)
%dir %{buildroot}/%{name}
%dir /run/%{name}

%changelog
*  Sun May 16 2021 Lee Cowdrey <lee@cowdrey.co.uk> 1.0.0
- initial
