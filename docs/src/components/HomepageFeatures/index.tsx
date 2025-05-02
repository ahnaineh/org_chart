import type { ReactNode } from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  icon: string;  // Font awesome icon class
  description: ReactNode;
  color: string; // CSS color for the icon background
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Fully Customizable',
    icon: 'fa-solid fa-palette',
    color: '#4c5ec5',
    description: (
      <>
        Customize every aspect of your organization chart.
        Change colors, shapes, fonts, and more to match your brand.
      </>
    ),
  },
  {
    title: 'Responsive & Interactive',
    icon: 'fa-solid fa-mobile-screen-button',
    color: '#ff5722',
    description: (
      <>
        Charts that look great on any device. Add interactive
        features like expand/collapse, tooltips, and click events.
      </>
    ),
  },
  {
    title: 'Export Ready',
    icon: 'fa-solid fa-file-export',
    color: '#4caf50',
    description: (
      <>
        Export your charts as images or PDFs with a single click.
        Perfect for presentations, reports, and documentation.
      </>
    ),
  },
  {
    title: 'Multiple Layouts',
    icon: 'fa-solid fa-sitemap',
    color: '#03a9f4',
    description: (
      <>
        Choose from various layouts including vertical, horizontal,
        and mixed orientation to best represent your organization.
      </>
    ),
  },
  {
    title: 'Lightning Fast',
    icon: 'fa-solid fa-bolt',
    color: '#ff9800',
    description: (
      <>
        Optimized for performance, even with thousands of nodes.
        Smooth animations and transitions without lag.
      </>
    ),
  },
  {
    title: 'Developer Friendly',
    icon: 'fa-solid fa-code',
    color: '#9c27b0',
    description: (
      <>
        Simple API, comprehensive documentation, and ready-to-use
        examples to get you started in minutes.
      </>
    ),
  },
];

function Feature({ title, icon, description, color }: FeatureItem) {
  return (
    <div className={clsx('col col--4', styles.featureCard)}>
      <div className={styles.card}>
        <div className={styles.cardHeader} style={{ backgroundColor: color }}>
          <i className={clsx(icon, styles.featureIcon)} />
        </div>
        <div className={styles.cardContent}>
          <Heading as="h3">{title}</Heading>
          <p>{description}</p>
        </div>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className={styles.sectionHeader}>
          <Heading as="h2">Key Features</Heading>
          <p>Everything you need to visualize your organizational structure</p>
        </div>
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
