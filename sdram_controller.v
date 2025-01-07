module sdram_controller (
input           clk,                 // Ceas de sistem
input           reset_n,             // Reset activ pe 0

// Interfață către driverul VGA
input    [18:0] addr,                // Adresa pixelului
input    [15:0] write_data,          // Date de scris
input           write_enable,        // Semnal de scriere
output   [15:0] read_data,           // Date citite
input           read_enable,         // Semnal de citire

// Interfață către SDRAM
output reg [12:0] DRAM_ADDR,
output reg [1:0]  DRAM_BA,
output reg        DRAM_CAS_N,
output reg        DRAM_CKE,
output reg        DRAM_CLK,
output reg        DRAM_CS_N,
inout  reg [15:0] DRAM_DQ,
output reg        DRAM_LDQM,
output reg        DRAM_RAS_N,
output reg        DRAM_UDQM,
output reg        DRAM_WE_N
);

    // Stările FSM-ului
    typedef enum reg [2:0] {
        INIT,
        IDLE,
        READ,
        WRITE,
        REFRESH
    } sdram_state_t;

    sdram_state_t state;

    // SDRAM Initialization Sequence
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= INIT;
            // Setare semnale implicite
            DRAM_CS_N <= 1;
            DRAM_RAS_N <= 1;
            DRAM_CAS_N <= 1;
            DRAM_WE_N <= 1;
            DRAM_CKE <= 0;
            DRAM_CLK <= 0;
        end else begin
            case (state)
                INIT: begin
                    // Secvența de inițializare SDRAM
                    state <= IDLE;
                end
                IDLE: begin
                    if (read_enable) begin
                        state <= READ;
                    end else if (write_enable) begin
                        state <= WRITE;
                    end
                end
                READ: begin
                    // Logica de citire
                    DRAM_CS_N <= 0;
                    DRAM_RAS_N <= 0;
                    DRAM_CAS_N <= 0;
                    DRAM_WE_N <= 1;
                    DRAM_ADDR <= addr[18:6];  // Adresa rândului
                    DRAM_BA <= addr[5:4];    // Banca
                    read_data <= DRAM_DQ;    // Date citite
                    state <= IDLE;
                end
                WRITE: begin
                    // Logica de scriere
                    DRAM_CS_N <= 0;
                    DRAM_RAS_N <= 0;
                    DRAM_CAS_N <= 0;
                    DRAM_WE_N <= 0;
                    DRAM_ADDR <= addr[18:6]; // Adresa rândului
                    DRAM_BA <= addr[5:4];   // Banca
                    DRAM_DQ <= write_data;  // Date de scris
                    state <= IDLE;
                end
                REFRESH: begin
                    // Operație de refresh (perioadică)
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
