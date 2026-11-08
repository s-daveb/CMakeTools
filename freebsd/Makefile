# Created by: Your Name <your@email.com>
# $FreeBSD$

PORTNAME=	strict
DISTVERSION=	0.1.0
CATEGORIES=	net-im

MAINTAINER=	your@email.com
COMMENT=	C++20 Slack clone (web backend)

LICENSE=	MIT

USES=		cmake compiler:c++20-lang

USE_GITHUB=	yes
GH_ACCOUNT=	yourgithub

# libwebsockets is built via FetchContent, not as a port dep.
# If you prefer the port, uncomment:
# LIB_DEPENDS=	libwebsockets.so:net/libwebsockets

PLIST_FILES=	bin/strict \
		"@sample etc/strict.conf.example" \
		share/strict/static/README.md

.include <bsd.port.mk>
