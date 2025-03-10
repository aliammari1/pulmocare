from datetime import datetime
import os
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from config import Config
import logging

logger = logging.getLogger(__name__)

class ReportGenerator:
    """Generate PDF reports from medical findings"""
    
    def __init__(self):
        self.styles = getSampleStyleSheet()
        self.custom_style = ParagraphStyle(
            'CustomStyle',
            parent=self.styles['Normal'],
            fontSize=10,
            spaceAfter=12
        )
    
    def generate_pdf(self, report_data, output_path=None):
        """Generate PDF report from analysis data"""
        try:
            if not output_path:
                # Generate unique filename
                timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
                filename = f"medical_report_{timestamp}.pdf"
                output_path = os.path.join(Config.PDF_EXPORT_PATH, filename)
            
            # Create PDF document
            doc = SimpleDocTemplate(
                output_path,
                pagesize=letter,
                rightMargin=72,
                leftMargin=72,
                topMargin=72,
                bottomMargin=72
            )
            
            # Build content
            story = []
            
            # Add header
            story.append(Paragraph(
                "Medical Report Analysis",
                self.styles['Title']
            ))
            story.append(Spacer(1, 12))
            
            # Add timestamp
            story.append(Paragraph(
                f"Generated on: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}",
                self.custom_style
            ))
            story.append(Spacer(1, 12))
            
            # Add findings table
            if 'findings' in report_data:
                story.append(Paragraph("Findings:", self.styles['Heading2']))
                story.append(Spacer(1, 12))
                
                findings_data = [[
                    'Condition',
                    'Severity',
                    'Description',
                    'Confidence'
                ]]
                
                for finding in report_data['findings']:
                    findings_data.append([
                        finding['condition'],
                        finding['severity'].capitalize(),
                        finding['description'],
                        f"{finding['confidence_score']:.1f}%"
                    ])
                
                findings_table = Table(
                    findings_data,
                    colWidths=[1.5*inch, inch, 3*inch, inch]
                )
                findings_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 11),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                    ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
                    ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
                    ('FONTSIZE', (0, 1), (-1, -1), 9),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                story.append(findings_table)
                story.append(Spacer(1, 20))
            
            # Add technical assessment
            if 'technical_assessment' in report_data:
                tech = report_data['technical_assessment']
                story.append(Paragraph("Technical Assessment:", self.styles['Heading2']))
                story.append(Spacer(1, 12))
                
                quality_data = [['Metric', 'Rating']]
                metrics = tech['quality_metrics']
                for key, value in metrics.items():
                    quality_data.append([
                        key.replace('_', ' ').capitalize(),
                        value.capitalize()
                    ])
                
                quality_table = Table(quality_data, colWidths=[2*inch, 2*inch])
                quality_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 11),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                    ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                story.append(quality_table)
                story.append(Spacer(1, 20))
            
            # Add summary and recommendations
            if 'overall_assessment' in report_data:
                story.append(Paragraph("Summary:", self.styles['Heading2']))
                story.append(Spacer(1, 12))
                
                assessment = report_data['overall_assessment']
                story.append(Paragraph(
                    assessment['summary'],
                    self.custom_style
                ))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph(
                    f"Risk Level: {assessment['risk_level'].upper()}",
                    self.styles['Heading3']
                ))
                story.append(Spacer(1, 12))
                
                story.append(Paragraph(
                    "Recommendations:",
                    self.styles['Heading3']
                ))
                story.append(Paragraph(
                    assessment['follow_up'],
                    self.custom_style
                ))
            
            # Build PDF
            doc.build(story)
            logger.info(f"Generated PDF report at {output_path}")
            
            return output_path
            
        except Exception as e:
            logger.error(f"Error generating PDF report: {str(e)}")
            raise