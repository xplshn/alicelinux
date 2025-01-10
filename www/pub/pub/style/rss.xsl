<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" doctype-system="about:legacy-compat" indent="yes" />
    <xsl:template match="/rss/channel">

        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />

            <title>
                <xsl:value-of select="title" />
            </title>

            <link rel="shortcut icon" type="image/ico" href="https://cdn.ctis.me/file/ctisme-cdn/www.ctis.me/resources/images/favicon.png" />
            <link rel="stylesheet" type="text/css" href="/pub/style/style.css" />
        </head>
        <body class="rss-xsl">

            <h2 class="rss-xsl-title">
                <a href="{ link }"><xsl:value-of select="title" /></a>
            </h2>

            <p class="rss-xsl-description">
                <xsl:value-of select="description" />. Last built <span class="rss-xsl-lastBuild"><xsl:value-of select="lastBuildDate" /></span>.
            </p>

            <ul class="rss-xsl-posts">
                <xsl:for-each select="./item">

                    <li class="rss-xsl-posts rss-xsl-post">

                        <h2 class="rss-xsl-post-title">
                            <a href="{ link }" class="rss-xsl-post-link">
                                <xsl:value-of select="title" />
                            </a>
                        </h2>

                        <h5 class="rss-xsl-post-pubdate"><xsl:value-of select="pubDate" /></h5>

                        <p class="rss-xsl-post-preview">
                            <xsl:value-of select="description" />
                            <span> (<a href="{ link }" class="rss-xsl-post-more">read more</a>)</span>
                        </p>

                    </li>

                </xsl:for-each>
            </ul>

            <p class="rss-xsl-home">
                <a href="{ link }" class="rss-xsl-home-link">View all posts on <strong>blog.ctis.me</strong></a>
            </p>

<footer>
<div class="left"><a href="https://github.com/ctis-me/hugo-werc">Descended from werc</a> | <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode">© Charlton Trezevant</a></div>
</footer>

        </body>
        </html>

    </xsl:template>

</xsl:stylesheet>
