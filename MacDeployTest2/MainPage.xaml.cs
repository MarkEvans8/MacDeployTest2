namespace MacDeployTest2
{
    public partial class MainPage : ContentPage
    {
        int count = 0;

        public MainPage()
        {
            InitializeComponent();
        }

        private void OnCounterClicked(object? sender, EventArgs e)
        {
            count++;

            if (count == 1)
                CounterBtn.Text = $"Clicked {count} time";
            else
                CounterBtn.Text = $"Clicked {count} times";

            SemanticScreenReader.Announce(CounterBtn.Text);
            
            // Test debugging workflow - throw exception on 5th click
            if (count == 5)
            {
                int problematicValue = count;
                string message = $"Debug test: reached count {problematicValue}";
                throw new InvalidOperationException(message);
            }
        }
    }
}
