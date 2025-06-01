// filepath: c:\Users\ahnai\Projects\org_chart\docs\src\components\AnimatedOrgChart\SimpleChart.tsx
import React from 'react';
import styles from './styles.module.css';

// A simple non-animated version to test if the issue is with the animation code
export default function SimpleChart(): React.ReactElement {
    return (
        <div className={styles.animatedChartContainer}>
            <div className={styles.animatedChart} style={{
                backgroundColor: '#f0f4f9',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '1.2rem',
                color: '#3f51b5',
                fontWeight: 'bold'
            }}>
                Org Chart Visualization
            </div>
        </div>
    );
}
