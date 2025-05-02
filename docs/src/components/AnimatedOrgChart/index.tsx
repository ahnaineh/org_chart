import React, { useEffect, useRef } from 'react';
import styles from './styles.module.css';

// Simple animated org chart for the homepage
export default function AnimatedOrgChart(): React.ReactElement {
    const canvasRef = useRef<HTMLCanvasElement>(null);

    useEffect(() => {
        const canvas = canvasRef.current;
        if (!canvas) return;

        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        // Set canvas dimensions
        const resizeCanvas = () => {
            const { width, height } = canvas.getBoundingClientRect();
            canvas.width = width;
            canvas.height = height;
        };

        resizeCanvas();
        window.addEventListener('resize', resizeCanvas);

        // Define org chart nodes
        const ceo = { x: canvas.width / 2, y: 50, radius: 25, label: 'CEO', color: '#3f51b5' };
        const cto = { x: canvas.width / 3, y: 160, radius: 20, label: 'CTO', color: '#5768c7' };
        const cfo = { x: canvas.width / 2, y: 160, radius: 20, label: 'CFO', color: '#5768c7' };
        const cmo = { x: (canvas.width / 3) * 2, y: 160, radius: 20, label: 'CMO', color: '#5768c7' };

        const engineers = [
            { x: canvas.width / 4, y: 250, radius: 16, label: 'Eng', color: '#7683d2' },
            { x: canvas.width / 3, y: 250, radius: 16, label: 'Eng', color: '#7683d2' },
            { x: (canvas.width / 5) * 2, y: 250, radius: 16, label: 'QA', color: '#7683d2' }
        ];

        const finance = [
            { x: canvas.width / 2, y: 250, radius: 16, label: 'Acc', color: '#7683d2' },
        ];

        const marketing = [
            { x: (canvas.width / 3) * 2, y: 250, radius: 16, label: 'Mkt', color: '#7683d2' },
            { x: (canvas.width / 4) * 3, y: 250, radius: 16, label: 'PR', color: '#7683d2' },
        ];

        // Animation variables
        let animationFrame: number;
        let t = 0;

        // Animation function
        const animate = () => {
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            t += 0.005;
            const pulse = Math.sin(t) * 5;

            // Draw connections
            ctx.strokeStyle = '#d0d5e8';
            ctx.lineWidth = 2;

            // CEO to executives
            drawConnection(ctx, ceo, cto);
            drawConnection(ctx, ceo, cfo);
            drawConnection(ctx, ceo, cmo);

            // CTO to engineers
            engineers.forEach(eng => drawConnection(ctx, cto, eng));

            // CFO to finance
            finance.forEach(fin => drawConnection(ctx, cfo, fin));

            // CMO to marketing
            marketing.forEach(mkt => drawConnection(ctx, cmo, mkt));

            // Draw nodes with pulsing effect
            drawNode(ctx, ceo, pulse);
            drawNode(ctx, cto, pulse * 0.8);
            drawNode(ctx, cfo, pulse * 0.8);
            drawNode(ctx, cmo, pulse * 0.8);

            engineers.forEach(eng => drawNode(ctx, eng, pulse * 0.6));
            finance.forEach(fin => drawNode(ctx, fin, pulse * 0.6));
            marketing.forEach(mkt => drawNode(ctx, mkt, pulse * 0.6));

            animationFrame = requestAnimationFrame(animate);
        };

        animate();

        return () => {
            window.removeEventListener('resize', resizeCanvas);
            cancelAnimationFrame(animationFrame);
        };
    }, []);

    const drawNode = (
        ctx: CanvasRenderingContext2D,
        node: { x: number; y: number; radius: number; label: string; color: string },
        pulse: number
    ) => {
        // Draw circle with glow effect
        ctx.beginPath();
        ctx.arc(node.x, node.y, node.radius + pulse, 0, Math.PI * 2);
        ctx.fillStyle = node.color;
        ctx.shadowColor = node.color;
        ctx.shadowBlur = 15;
        ctx.fill();
        ctx.shadowBlur = 0;

        // Draw label
        ctx.font = '12px "Space Grotesk", sans-serif';
        ctx.fillStyle = '#ffffff';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(node.label, node.x, node.y);
    };

    const drawConnection = (
        ctx: CanvasRenderingContext2D,
        nodeA: { x: number; y: number; radius: number },
        nodeB: { x: number; y: number; radius: number }
    ) => {
        ctx.beginPath();
        ctx.moveTo(nodeA.x, nodeA.y + nodeA.radius);
        ctx.lineTo(nodeB.x, nodeB.y - nodeB.radius);
        ctx.stroke();
    };

    return (
        <div className={styles.animatedChartContainer}>
            <canvas ref={canvasRef} className={styles.animatedChart} />
        </div>
    );
}
