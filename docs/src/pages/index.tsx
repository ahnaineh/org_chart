import type { ReactNode } from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/getting-started/Installation">
            Get into some cool stuff!
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title}`}
      description="Create beautiful, organization charts with ease">
      <HomepageHeader />
      <main>
        <section className={styles.features}>
          <div className="container">
            <div className="row">
              <div className={clsx('col col--4')}>
                <div className="text--center">
                  <img
                    className={styles.featureImg}
                    src="/img/org_chart_hierarchy.svg"
                    alt="Organization Hierarchy"
                  />
                </div>
                <div className="text--center padding-horiz--md">
                  <Heading as="h3">Visualize Your Organization</Heading>
                  <p>Create beautiful, interactive organization charts with ease</p>
                </div>
              </div>
              <div className={clsx('col col--4')}>
                <div className="text--center">
                  <img
                    className={styles.featureImg}
                    src="/img/org_chart_data.svg"
                    alt="Data Integration"
                  />
                </div>
                <div className="text--center padding-horiz--md">
                  <Heading as="h3">Data Integration</Heading>
                  <p>Connect to your existing HR systems and databases</p>
                </div>
              </div>
              <div className={clsx('col col--4')}>
                <div className="text--center">
                  <img
                    className={styles.featureImg}
                    src="/img/org_chart_responsive.svg"
                    alt="Responsive Design"
                  />
                </div>
                <div className="text--center padding-horiz--md">
                  <Heading as="h3">Responsive Design</Heading>
                  <p>Works on desktops, tablets, and mobile devices</p>
                </div>
              </div>
            </div>

            <div className="text--center margin-top--xl">
              <img
                className={styles.demoImage}
                src="/img/org_chart_demo.png"
                alt="Organization Chart Demo"
              />
              <Heading as="h2" className="margin-top--md">
                Modern Organization Chart Solutions
              </Heading>
              <p>Build, maintain, and share interactive organization charts with our powerful tools</p>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
