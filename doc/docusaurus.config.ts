import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';


const config: Config = {
  title: 'Org Chart',
  tagline: 'Professional Flutter Charts for Organizations & Family Trees',
  favicon: 'img/icon.png',

  trailingSlash: true,

  // Set the production url of your site here
  url: 'https://ahnaineh.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/org_chart/',
  deploymentBranch: 'gh-pages',
  

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'ahnaineh', // Usually your GitHub org/user name.
  projectName: 'org_chart', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl:
            'https://github.com/ahnaineh/org_chart/tree/main/doc/',
          showLastUpdateAuthor: true,
          showLastUpdateTime: true,
          breadcrumbs: true,
        },
        // blog: {
        //   showReadingTime: true,
        //   feedOptions: {
        //     type: ['rss', 'atom'],
        //     xslt: true,
        //   },
        //   // Please change this to your repo.
        //   // Remove this to remove the "edit this page" links.
        //   editUrl:
        //     'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        //   // Useful options to enforce blogging best practices
        //   onInlineTags: 'warn',
        //   onInlineAuthors: 'warn',
        //   onUntruncatedBlogPosts: 'warn',
        // },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  markdown: {
    mermaid: true,
  },
  themes: ['@docusaurus/theme-mermaid'],

  themeConfig: {
    algolia: {
      appId: "L821DBNWTZ",
      apiKey: "52057088db326099ebce184a8d77b4b4",
      indexName: "ahnainehio",
      contextualSearch: true,
    },
    image: 'img/org-chart-showcase.png',
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    announcementBar: {
      id: 'v5_release',
      content:
        '🎉 <b>Version 5.1.0 is here!</b> Enhanced performance, new Genogram features, and improved customization. <a href="/org_chart/docs/7.0.0-changelog">See what\'s new →</a>',
      backgroundColor: '#667eea',
      textColor: '#ffffff',
      isCloseable: true,
    },
    navbar: {
      title: 'ORG CHART',
      logo: {
        alt: 'ORG CHART Logo',
        src: 'img/icon.png',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          to: '/docs/2.0.0-getting-started/01-installation',
          label: 'Getting Started',
          position: 'left',
        },
        {
          to: '/docs/6.0.0-examples/01-live-playground',
          label: 'Examples',
          position: 'left',
        },
        {
          to: '/docs/3.0.0-orgchart/01-overview',
          label: 'API',
          position: 'left',
        },
        {
          to: '/docs/7.0.0-changelog',
          label: 'Changelog',
          position: 'left',
        },
        {
          href: 'https://github.com/ahnaineh/org_chart',
          label: 'GitHub',
          position: 'right',
          className: 'navbar-github-link',
        },
        {
          href: 'https://pub.dev/packages/org_chart',
          label: 'Pub',
          position: 'right',
          className: 'navbar-pub-link',
        },
      ],
    },
    footer: {
      style: 'dark',
      logo: {
        alt: 'Org Chart Logo',
        src: 'img/icon.png',
        width: 160,
      },
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/2.0.0-getting-started/01-installation',
            },
            {
              label: 'Examples',
              to: '/docs/6.0.0-examples/01-live-playground',
            },
            {
              label: 'API Reference',
              to: '/docs/3.0.0-orgchart/01-overview',
            },
            {
              label: 'Changelog',
              to: '/docs/7.0.0-changelog',
            },
          ],
        },
        {
          title: 'Community',
          items: [
            {
              label: 'Stack Overflow',
              href: 'https://stackoverflow.com/questions/tagged/flutter-org-chart',
            },
            {
              label: 'Twitter',
              href: 'https://twitter.com/flutterdev',
            },
            {
              label: 'Discord',
              href: 'https://discord.gg/flutter',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/ahnaineh/org_chart',
            },
            {
              label: 'Pub.dev',
              href: 'https://pub.dev/packages/org_chart',
            },
            {
              label: 'Report Issues',
              href: 'https://github.com/ahnaineh/org_chart/issues',
            },
          ],
        },

      ],
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['dart', 'yaml', 'bash']
    },
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
    tableOfContents: {
      minHeadingLevel: 2,
      maxHeadingLevel: 5,
    },
    mermaid: {
      theme: { light: 'neutral', dark: 'dark' },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
