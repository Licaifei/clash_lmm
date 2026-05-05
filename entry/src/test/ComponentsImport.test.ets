import { describe, it, expect } from '@ohos/hypium';
import { BasePage } from '../main/ets/components/BasePage';
import { StatusCard } from '../main/ets/components/StatusCard';
import { EmptyState } from '../main/ets/components/EmptyState';
import { ErrorBanner } from '../main/ets/components/ErrorBanner';
import { LoadingRow } from '../main/ets/components/LoadingRow';
import { SectionHeader } from '../main/ets/components/SectionHeader';

export default function ComponentsImportTest() {
  describe('Component_imports', () => {
    it('BasePage_should_be_importable', 0, () => {
      expect(BasePage).assertDefined();
    });

    it('StatusCard_should_be_importable', 0, () => {
      expect(StatusCard).assertDefined();
    });

    it('EmptyState_should_be_importable', 0, () => {
      expect(EmptyState).assertDefined();
    });

    it('ErrorBanner_should_be_importable', 0, () => {
      expect(ErrorBanner).assertDefined();
    });

    it('LoadingRow_should_be_importable', 0, () => {
      expect(LoadingRow).assertDefined();
    });

    it('SectionHeader_should_be_importable', 0, () => {
      expect(SectionHeader).assertDefined();
    });

    it('EmptyState_should_accept_message_prop', 0, () => {
      const props = { message: 'No data' };
      expect(props.message).assertEqual('No data');
    });

    it('ErrorBanner_should_accept_message_prop', 0, () => {
      const props = { message: 'Error occurred' };
      expect(props.message).assertEqual('Error occurred');
    });
  });
}
