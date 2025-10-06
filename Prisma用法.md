你说的 Prisma 用法，我给你分成几个方面来梳理一下（偏实用，适合你直接上手）：

## Prisma 是什么

Prisma 是一个现代的 Node.js ORM，帮助你在数据库里进行 增删改查（CRUD），支持 PostgreSQL、MySQL、SQLite、MongoDB 等。
它的优势是：

类型安全（和 TypeScript 配合非常爽）。

自动生成数据库模型的客户端。

迁移系统（Migrations）方便管理数据库结构。

## 核心组成

schema.prisma：定义数据库模型（类似于数据表结构）。

Prisma Client：自动生成的客户端，用来写 CRUD。

Prisma Migrate：数据库迁移工具。

## 基本用法
① 安装
   pnpm add prisma @prisma/client
   pnpm prisma init   # 初始化，会生成 prisma/schema.prisma

② 定义模型

编辑 prisma/schema.prisma：

```shell
datasource db {
provider = "postgresql"   // 可以换成 mysql/sqlite/mongodb
url      = env("DATABASE_URL")
}

generator client {
provider = "prisma-client-js"
}

model User {
id    Int    @id @default(autoincrement())
name  String
email String @unique
}
```

③ 生成迁移

```shell
pnpm prisma migrate dev --name init
```

会生成数据库表 + prisma/migrations 目录。

④ 使用 Prisma Client

在项目里写代码（例如 src/index.js）：

```nodejs
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
// 新增
const newUser = await prisma.user.create({
data: {
name: 'Tom',
email: 'tom@example.com',
},
});
console.log('Created:', newUser);

// 查询
const users = await prisma.user.findMany();
console.log('All users:', users);

// 更新
const updateUser = await prisma.user.update({
where: { id: 1 },
data: { name: 'Jerry' },
});

// 删除
await prisma.user.delete({ where: { id: 1 } });
}

main()
.catch(e => console.error(e))
.finally(async () => await prisma.$disconnect());
```

##  常用查询

条件查询

```js
const user = await prisma.user.findUnique({
  where: { email: 'tom@example.com' },
});

```


多条件 + 排序

```js
const users = await prisma.user.findMany({
where: { name: { contains: 'o' } },
orderBy: { id: 'desc' },
take: 10,
skip: 5,
});

```


关联查询

```js
model Post {
id     Int   @id @default(autoincrement())
title  String
author User? @relation(fields: [authorId], references: [id])
authorId Int?
}

const posts = await prisma.post.findMany({
include: { author: true },
});
```

5. 常见命令

数据库迁移

```shell
pnpm prisma migrate dev --name add_user_table

```

查看数据库结构 (GUI)

```shell
pnpm prisma studio

```

重新生成客户端

```shell
pnpm prisma generate

```

⚡ 总结：
Prisma 的核心流程是 写 schema → 迁移 → 用 Client 调用。你平时写 CRUD 基本都在用 prisma.xxx.findMany()、create()、update()、delete()。