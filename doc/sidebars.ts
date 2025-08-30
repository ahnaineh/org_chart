import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {
  tutorialSidebar: [
    {
      type: 'category',
      label: '🚀 Introduction',
      collapsed: false,
      items: [
        '1.0.0-introduction/01-welcome',
        '1.0.0-introduction/02-features',
        '1.0.0-introduction/03-comparison',
      ],
    },
    {
      type: 'category',
      label: '📚 Getting Started',
      collapsed: false,
      items: [
        '2.0.0-getting-started/01-installation',
        '2.0.0-getting-started/02-basic-usage',
        '2.0.0-getting-started/04-migration-guide',
      ],
    },
    {
      type: 'category',
      label: '🏢 Organization Chart',
      collapsed: true,
      items: [
        '3.0.0-orgchart/01-overview',
        '3.0.0-orgchart/02-controller',
        '3.0.0-orgchart/03-widget',
      ],
    },
    {
      type: 'category',
      label: '👨‍👩‍👧‍👦 Genogram',
      collapsed: true,
      items: [
        '4.0.0-genogram/01-overview',
        '4.0.0-genogram/02-controller',
        '4.0.0-genogram/03-widget',
      ],
    },

    {
      type: 'category',
      label: '💡 Examples',
      collapsed: true,
      items: [
        '6.0.0-examples/01-live-playground',
      ],
    },
    '7.0.0-changelog',
  ],
};

export default sidebars;
