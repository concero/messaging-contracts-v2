    Colors:
    - Core Contracts and Interfaces: #fafafa
    - Internal Libraries: #ffe6e6
    - Common Libraries: #fff0e6
    - Third-Party Dependencies: #f0ffe6
    
    Lines:
    - Inheritance Relationships: Solid Line
    - Usage Relationships: Dotted Line

```mermaid
classDiagram
    %% Core Contracts and Interfaces
    class ConceroOwnable
    class Base
    class Message
    class Operator
    class Owner
    class GenericStorage
    class ConceroRouter
    class IConceroRouter

    %% Internal Libraries
    class Storage
    class Namespaces
    class RouterSlots

    %% Common Libraries
    class GenericStorageLib
    class Constants
    class Signer
    class Utils
    class MessageLib
    class MessageLibConstants
    class SupportedChains

    %% Third-Party Dependencies
    class IERC20
    class SafeERC20

    %% Inheritance Relationships
    Operator <|-- ConceroRouter
    Owner <|-- ConceroRouter
    GenericStorage <|-- ConceroRouter
    Message <|-- ConceroRouter

    ConceroOwnable <|-- Base
    Base <|-- GenericStorage
    Base <|-- Message
    Base <|-- Operator
    Base <|-- Owner
    IConceroRouter <|-- Message

    %% Usage Relationships (..>)
    Storage ..> GenericStorageLib
    Storage ..> Namespaces

    Message ..> IERC20
    Message ..> SafeERC20
    Message ..> MessageLib
    Message ..> Signer
    Message ..> Utils
    Message ..> Storage
    Message ..> IConceroRouter

    Operator ..> IERC20
    Operator ..> SafeERC20
    Operator ..> Constants
    Operator ..> SupportedChains

    Owner ..> IERC20
    Owner ..> SafeERC20

    GenericStorage ..> GenericStorageLib
    GenericStorage ..> Namespaces

    %% Defining Class Styles for Readability
    class ConceroRouter:::main
    class Base:::contract
    class Message:::contract
    class Operator:::contract
    class Owner:::contract
    class GenericStorage:::contract
    class ConceroOwnable:::contract
    class IConceroRouter:::contract

    class Storage:::internallib
    class Namespaces:::internallib
    class RouterSlots:::internallib

    class GenericStorageLib:::commonlib
    class MessageLib:::commonlib
    class MessageLibConstants:::commonlib
    class Signer:::commonlib
    class Utils:::commonlib
    class Constants:::commonlib
    class SupportedChains:::commonlib

    class IERC20:::thirdparty
    class SafeERC20:::thirdparty

    classDef main fill:#fafafa,stroke:#000000
    classDef contract fill:#e6f3ff,stroke:#000000
    classDef commonlib fill:#fff0e6,stroke:#000000
    classDef internallib fill:#ffe6e6,stroke:#000000
    classDef thirdparty fill:#f0ffe6,stroke:#000000
```
