// Question Components
export { ShortTextQuestion, ShortTextTemplate } from './ShortTextQuestion';
export { LongTextQuestion, LongTextTemplate } from './LongTextQuestion';
export { MultipleChoiceQuestion, MultipleChoiceTemplate } from './MultipleChoiceQuestion';
export { CheckboxQuestion, CheckboxTemplate } from './CheckboxQuestion';
export { EmailQuestion, EmailTemplate } from './EmailQuestion';
export { NumberQuestion, NumberTemplate } from './NumberQuestion';
export { DropdownQuestion, DropdownTemplate } from './DropdownQuestion';

// Base types and components
export type { QuestionData, QuestionProps, QuestionTemplateProps } from './BaseQuestion';
export { BaseQuestion } from './BaseQuestion';

// Question type mapping
import { ShortTextQuestion, ShortTextTemplate } from './ShortTextQuestion';
import { LongTextQuestion, LongTextTemplate } from './LongTextQuestion';
import { MultipleChoiceQuestion, MultipleChoiceTemplate } from './MultipleChoiceQuestion';
import { CheckboxQuestion, CheckboxTemplate } from './CheckboxQuestion';
import { EmailQuestion, EmailTemplate } from './EmailQuestion';
import { NumberQuestion, NumberTemplate } from './NumberQuestion';
import { DropdownQuestion, DropdownTemplate } from './DropdownQuestion';

export const QUESTION_COMPONENTS = {
  'short-text': ShortTextQuestion,
  'long-text': LongTextQuestion,
  'multiple-choice': MultipleChoiceQuestion,
  'checkbox': CheckboxQuestion,
  'email': EmailQuestion,
  'number': NumberQuestion,
  'dropdown': DropdownQuestion,
};

export const QUESTION_TEMPLATES = [
  ShortTextTemplate,
  LongTextTemplate,
  MultipleChoiceTemplate,
  CheckboxTemplate,
  EmailTemplate,
  NumberTemplate,
  DropdownTemplate,
];
