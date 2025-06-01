import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';


const config: Config = {
  title: 'Org Chart',
  tagline: 'From Interns to CEOs—Plot Them All!',
  favicon: 'img/favicon.ico',

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
            'https://github.com/ahnaineh/org_chart/tree/docs/docs/',
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
      id: 'support_us',
      content:
        '✨ If you like Org Chart, give it a star on <a target="_blank" rel="noopener noreferrer" href="https://github.com/ahnaineh/org_chart">GitHub</a>',
      backgroundColor: 'rgba(63, 81, 181, 0.1)',
      textColor: 'var(--ifm-color-primary)',
      isCloseable: true,
    },
    navbar: {
      title: 'ORG CHART',
      logo: {
        alt: 'ORG CHART Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Documentation',
        },
        {
          to: '/docs/getting-started/Installation',
          label: 'Getting Started',
          position: 'left',
        },
        {
          to: '/docs/examples',
          label: 'Examples',
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
        src: 'img/logo.svg',
        width: 160,
      },
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/getting-started/Installation',
            },
            {
              label: 'Examples',
              to: '/docs/examples',
            },
            {
              label: 'API Reference',
              to: '/docs/category/common',
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
      additionalLanguages: ['dart']
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
